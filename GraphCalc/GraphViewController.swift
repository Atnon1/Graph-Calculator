//
//  ViewController.swift
//  GraphDrawer
//
//  Created by Admin on 21.11.17.
//  Copyright © 2017 MakeY. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {

    @IBOutlet var graphView: GraphView! {
        didSet {
            let pinchRecognizer = UIPinchGestureRecognizer(target: graphView, action: #selector(graphView.changeScale(byReactingTo:)))
            graphView.addGestureRecognizer(pinchRecognizer)
            let panRecognizer = UIPanGestureRecognizer(target: graphView, action: #selector(graphView.moveOrigin(byReactingTo:)))
            graphView.addGestureRecognizer(panRecognizer)
            let tapRecognizer = UITapGestureRecognizer(target: graphView, action: #selector(graphView.moveOriginToPoint(byReactingTo:)))
            tapRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(tapRecognizer)
            
            graphView.navigationBarHeight = self.navigationController?.navigationBar.bounds.height
            graphView.drawnFunction = drawnFunction
        }
    }
    
    override func viewDidLayoutSubviews() {
        if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            graphView.axesOrigin = nil
        }
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            graphView.loadData()
        }
    }
    
    /*private func restoreGraphState()->(function: ((CGFloat) -> CGFloat)?,description: String){
        let calculatorBrain = CalculatorBrain()
        calculatorBrain.f
    }*/
    
    var drawnFunction: ((CGFloat)->CGFloat)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        graphView.loadData()
    }

}

