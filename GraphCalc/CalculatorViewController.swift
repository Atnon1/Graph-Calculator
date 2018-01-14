//
//  ViewController.swift
//  Calculator
//
//  Created by Admin on 22.09.17.
//  Copyright © 2017 MakeY. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("calc")
    }
    
    
    @IBOutlet weak var display: UILabel!

    @IBOutlet weak var variableDisplay: UILabel!
    
    @IBOutlet weak var graphButton: UIButton!
    
    var userIsInTheMiddleOfTyping = false
    
    var isPending = false {
        didSet {
            graphButton.isEnabled = !isPending
        }
    }
    
    @IBOutlet weak var historyDisplay: UILabel!

    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            display.text = textCurrentlyInDisplay + digit
        } else {
            display.text = digit
            userIsInTheMiddleOfTyping = true
        }
    }
    
    @IBAction func touchFloatingPoint(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            if !textCurrentlyInDisplay.contains(".") {
                display.text = textCurrentlyInDisplay + "."
            }
        } else {
            display.text = "0."
            userIsInTheMiddleOfTyping = true
        }
    }
    
    
    @IBAction func clear(_ sender: UIButton) {
        userIsInTheMiddleOfTyping = false
        brain.clear()
        displayValue = 0
        historyDisplay.text = " "
        variableDisplay.text = " "
        mDictionary = [:]
    }
    
    
    @IBAction func undo(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            if display.text?.characters.count == 1 {
                userIsInTheMiddleOfTyping = false
                displayValue = 0
            } else {
                display.text = String(display.text!.characters.dropLast())
            }
        } else {
            displayValue = 0
            brain.undo()
            evaluateExprassion(using: mDictionary)
        }
    }
    
    let formatter: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.maximumFractionDigits = 6
        _formatter.minimumIntegerDigits = 1
        return _formatter
    }()
    
    var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        
        set {
            display.text = formatter.string(from: NSNumber(value: newValue))
        }
    }

    private var brain = CalculatorBrain()
    
    var mDictionary: Dictionary<String,Double> = [:]
    
    @IBAction func inputVariable(_ sender: UIButton) {
        mDictionary["M"] = displayValue
        variableDisplay.text = formatter.string(from: displayValue as NSNumber)
        evaluateExprassion(using: mDictionary)
        userIsInTheMiddleOfTyping = false
    }
    
    func evaluateExprassion(using variables: Dictionary<String,Double>? = nil) {
        let evaluation = brain.evaluate(using: variables)
        //variableDisplay.text = formatter.string(from: NSNumber(value: displayValue))
        if evaluation.result != nil &&  !evaluation.hasError{
                displayValue = evaluation.result!
        } else {
            display.text = "Error"
        }
        
        if evaluation.description != "" {
            historyDisplay.text = evaluation.description + (evaluation.isPending ? "..." : "=")
        } else {
            historyDisplay.text = " "
        }
        isPending = evaluation.isPending
    }
    
    @IBAction func setVariableOperand(_ sender: UIButton) {
        brain.setOperand(named: "M")
        evaluateExprassion(using: mDictionary)
    }
    
    //returns fuction expression (based on current calculatorBrain or saved state) or nil, if function is inavaliable, and function's desctiprion
    func formGraphFunction() -> (expression: ((CGFloat)->CGFloat)?, description: String) {
       /* func mathematicalFunction(_ variableValue: CGFloat)->CGFloat {
            var calculatorBrain = currentBrain
            let currentValue = Double(variableValue)
            return CGFloat(calculatorBrain.evaluate(using: ["M":currentValue]).result!)
        }*/
        var currentCalculatorBrain = brain
        if currentCalculatorBrain.evaluate().result == nil {
            currentCalculatorBrain.loadState()
            if currentCalculatorBrain.evaluate().result == nil {
                return (nil, "")
            }
        }
        let functionDescription = currentCalculatorBrain.evaluate().description
        let functionExpression = {(_ variableValue: CGFloat) -> CGFloat in
            let calculatorBrain = currentCalculatorBrain
            let currentValue = Double(variableValue)
            return CGFloat(calculatorBrain.evaluate(using: ["M":currentValue]).result!)
        }
        
        currentCalculatorBrain.saveState()
        return (functionExpression, functionDescription)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationViewController = segue.destination
        if let navigationViewController = destinationViewController as? UINavigationController {
            destinationViewController = navigationViewController.visibleViewController ?? destinationViewController
        }
        if let graphViewController = destinationViewController as? GraphViewController,
            segue.identifier  == "showGraph"{
                let function = formGraphFunction()
                graphViewController.drawnFunction = function.expression
                graphViewController.navigationItem.title = function.description
        }
    }

    @IBAction func performOperation(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        evaluateExprassion(using: mDictionary)
    }
        
}

