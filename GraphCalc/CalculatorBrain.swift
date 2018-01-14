 //
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Admin on 26.09.17.
//  Copyright © 2017 MakeY. All rights reserved.
//

import Foundation
 
 //The model

struct CalculatorBrain {
    
    private var accumulatorDidSet = false
    
    private var accumulator: Double? {
        didSet {
            accumulatorDidSet = true
        }
    }
    
    private var accumulatorString: String? {
        if let accumulatorValue = accumulator {
            return formatter.string(from: (accumulatorValue as NSNumber)) ?? String(accumulatorValue)
        } else {
            return nil
        }
    }
    
    var varsDictionary: [String:Double] = [:]
    
    public mutating func clear(){
        pendingBinaryOperation = nil
        accumulator = nil
        operationsSequence = []
    }
    
    public mutating func setOperand(named: String){
        if pendingBinaryOperation == nil {
            clear()
        }
        operationsSequence.append(.variable(named))
        accumulator = varsDictionary[named] ?? 0.0
    }
    
    mutating func setOperand( _ operand: Double) {
        if pendingBinaryOperation == nil {
            clear()
        }
        accumulator = operand
        operationsSequence.append(.operand(operand))
    }
    
    //Evaluates the result of operations consequence
    func evaluate(using variables: Dictionary<String,Double>? = nil) -> (result: Double?, isPending: Bool, description: String, hasError: Bool){
        var calculatorBrain = CalculatorBrain()
        if variables != nil {
            calculatorBrain.varsDictionary = variables!
        }
        for literal in operationsSequence {
            switch literal {
            case .operand(let value):
                calculatorBrain.setOperand(value)
            case .variable(let name):
                calculatorBrain.setOperand(named: name)
            case .operation(let symbol):
                calculatorBrain.performOperation(symbol)
            }
        }
        
        return (calculatorBrain.accumulator, calculatorBrain.pendingBinaryOperation != nil, calculatorBrain.createDescription(), detectErrors(in: calculatorBrain.accumulator))
    }
    
    private func detectErrors(in expression: Double?) -> Bool {
        return (expression == nil || expression!.isNaN || expression!.isInfinite)
    }
    
    //Forms textual description of operations consequence
    private func createDescription()-> String {
        var descriptions: [String] = []
        var resultIsPending = false
        for literal in operationsSequence{
            switch literal {
            case .operand(let value):
                descriptions += [formatter.string(from: (value as NSNumber)) ?? String(value)]
            case .variable(let name):
                descriptions += [name]
            case .operation(let symbol):
                if let operation = operations[symbol] {
                    switch operation {
                    case .constant(_):
                        descriptions.append(symbol)
                    case .unaryOperation(_):
                        if resultIsPending {
                            if var lastElement = descriptions.last {
                                lastElement = "("+lastElement+")"
                                switch symbol {
                                case "x²":
                                    lastElement = lastElement + "²"
                                default:
                                    lastElement = symbol + lastElement
                                }
                                descriptions = descriptions.dropLast() + [lastElement]
                            }
                        } else {
                            descriptions = ["("] + descriptions + [")"]
                            switch symbol {
                            case "x²":
                                descriptions.append("²")
                            default:
                                descriptions = [symbol] + descriptions
                            }
                        }
                    case .binaryOperation(_):
                        if symbol != "xʸ" {
                            descriptions.append(symbol)
                        } else {
                            descriptions = ["("] + descriptions + [")^"]
                        }
                        resultIsPending = true
                    case .equals:
                        resultIsPending = false
                    default: break
                    }
                }
            }
        }
        return descriptions.reduce("", +)
    }
    
    fileprivate var operationsSequence: [OperationsToStore] = []
    
    @available(iOS, deprecated, message: "No more needed")
    public var resultIsPending: Bool {
            return pendingBinaryOperation != nil
    }
    
    public mutating func undo() {
        if operationsSequence.count >= 1 {
            operationsSequence.remove(at: operationsSequence.count-1)
        }
    }
    
    fileprivate enum OperationsToStore {
        case operation(String)
        case operand(Double)
        case variable(String)
    }
    
    let formatter: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.maximumFractionDigits = 6
        _formatter.minimumIntegerDigits = 1
        return _formatter
    }()
    
    @available(iOS, deprecated, message: "No more needed")
    private var descriptions = [String]()
    
    @available(iOS, deprecated, message: "No more needed")
    var description: String {
        var returnString: String = ""
        for element in descriptions {
            returnString = returnString + element
        }
        return returnString
    }

    
    fileprivate enum Operation {
        case constant(Double)
        case unaryOperation((Double)->Double)
        case binaryOperation((Double,Double)->Double)
        case noArgumentOperation(()->Double)
        case equals
    }
    
    //The list of operations and their textual representation
    fileprivate var operations: Dictionary<String, Operation> = [
    "π"    : Operation.constant(Double.pi),
    "e"    : Operation.constant(M_E),
    "√"    : Operation.unaryOperation(sqrt),
    "cos"  : Operation.unaryOperation(cos),
    "sin"  : Operation.unaryOperation(sin),
    "±"    : Operation.unaryOperation({-$0}),
    "x²"   : Operation.unaryOperation({$0*$0}),
    "+"    : Operation.binaryOperation({$0+$1}),
    "-"    : Operation.binaryOperation({$0-$1}),
    "×"    : Operation.binaryOperation({$0*$1}),
    "÷"    : Operation.binaryOperation({$0/$1}),
    "xʸ"   : Operation.binaryOperation(pow),
    "Ran"  : Operation.noArgumentOperation({(Double(arc4random())/Double(UINT32_MAX)*100).rounded()/100}),
    "="    : Operation.equals
    ]
    
    
    mutating func performOperation(_ symbol: String) {
        if let operation = operations[symbol] {
            switch operation {
            case .constant(let value):
                accumulator = value
                operationsSequence.append(.operation(symbol))
            case .unaryOperation(let function):
                /*if let accumulatorValue = accumulator {
                    accumulator = function(accumulatorValue)
                }*/
                if accumulator == nil {
                    setOperand(0.0)
                }
                accumulator = function(accumulator!)
                operationsSequence.append(.operation(symbol))
            case .binaryOperation(let function):
                if accumulatorDidSet {
                    performPendingBinaryOperation()
                }
                if accumulator == nil {
                    setOperand(0.0)
                }
                /*if accumulator != nil {
                    pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: accumulator!)
                }*/
                pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: accumulator!)
                if !accumulatorDidSet && operationsSequence.count > 0{
                    operationsSequence.removeLast(1)
                }
                operationsSequence.append(.operation(symbol))
                accumulatorDidSet = false
            case .noArgumentOperation(let function):
                accumulator = function()
                operationsSequence.append(.operand(accumulator!))
            case .equals :
                performPendingBinaryOperation()
                operationsSequence.append(.operation(symbol))
            }
        }
    }
    
    
    private mutating func performPendingBinaryOperation(){
        if pendingBinaryOperation != nil && accumulator != nil {
            accumulator = pendingBinaryOperation!.perform(with: accumulator!)
            pendingBinaryOperation = nil
        }
    }
    
    private var pendingBinaryOperation: PendingBinaryOperation?
    
    private struct PendingBinaryOperation {
        let function : (Double,Double)->Double
        let firstOperand : Double
        func perform(with secondOperand: Double)->Double {
            return function(firstOperand, secondOperand)
        }
    }
    
    
    @available(iOS, deprecated, message: "No more needed")
    var result: Double? {
        get {
            return accumulator
        }
    }
    

    
}
 
 extension CalculatorBrain {
    //saves current state of operationsSequence into the UserDefaults' property "CalculatorsState"
    func saveState() {
        UserDefaults.standard.setValue(program, forKey: "CalculatorState")
        UserDefaults.standard.set(self.evaluate().description, forKey: "FunctionDefenition")
        print("saved")

    }

    mutating func loadState() {
        if let storedOperations = UserDefaults.standard.array(forKey: "CalculatorState") {
        program = storedOperations
        print("loaded")
        }
    }
    
    var program: [Any] {
        get {
            var tempProgram: [Any] = []
            for item in operationsSequence{
                switch item {
                case .operand(let value):
                    tempProgram.append(value)
                case .operation(let symbol):
                    tempProgram.append(symbol)
                case .variable(let name):
                    tempProgram.append(name)
                }
            }
            return tempProgram
        }
        set {
            operationsSequence = []
            for item in newValue {
                if let operand = item as? Double {
                    operationsSequence.append(.operand(operand))
            } else if let stringValue = item as? String {
                    if operations[stringValue] != nil {
                        operationsSequence.append(.operation(stringValue))
                    } else {
                        operationsSequence.append(.variable(stringValue))
                    }
                }
            }
        }
    }
 }
