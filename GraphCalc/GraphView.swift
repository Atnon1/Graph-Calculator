//
//  GraphView.swift
//  GraphDrawer
//
//  Created by Admin on 21.11.17.
//  Copyright © 2017 MakeY. All rights reserved.
//

import UIKit

//@IBDesignable

class GraphView: UIView {
    var navigationBarHeight: CGFloat?
    var axesDrawer = AxesDrawer()
    @IBInspectable
    var color = UIColor.green
    @IBInspectable
    var scale: CGFloat = 40.0 {didSet { setNeedsDisplay()}}
    //var axesOriginOffset = CGPoint(x: 0.0, y: 0.0) { didSet { setNeedsDisplay() } }
    let curve = UIBezierPath()
    /*private var axesOrigin: CGPoint {
        return CGPoint(x: bounds.midX + axesOriginOffset.x, y: bounds.midY+axesOriginOffset.y)
    }*/
    
    var axesOrigin: CGPoint! {didSet { setNeedsDisplay()}}
    
    public var drawnFunction:((CGFloat) -> CGFloat)? { didSet { setNeedsDisplay() } }
    

    func changeScale(byReactingTo pinchRecognizer: UIPinchGestureRecognizer){
        switch pinchRecognizer.state {
        case .changed:
            scale *= pinchRecognizer.scale
            pinchRecognizer.scale = 1.0
        case .ended:
            scale *= pinchRecognizer.scale
            pinchRecognizer.scale = 1.0
            saveData()
        default: break
        }
    }
    
    func drawMathFunction(fx: @escaping (CGFloat)->CGFloat){
        
        func drawGraph() {
            let maxY = bounds.maxY + bounds.height * 0.2
            let minY = bounds.minY - bounds.height * 0.2
            let maxX = Int(bounds.maxX*contentScaleFactor)
            let minX = Int(bounds.minY*contentScaleFactor)
            
            var curve: UIBezierPath?
            
           //print(minX, maxX, maxY, bounds.maxX, bounds.maxY, axesOrigin.x, axesOrigin.y)
            //curve.move(to: CGPoint(x: bounds.minX, y: axesOrigin.y + drawnFunction(((bounds.minX-axesOrigin.x)/scale))*scale))
            
            for x in minX...maxX {
                let y = (axesOrigin.y - fx((CGFloat(x)-axesOrigin.x)/scale)*scale)
                if y >= minY && y <= maxY, y.isZero || y.isNormal {
                    let nextPoint = CGPoint( x: CGFloat(x), y: y )
                    if curve != nil {
                        curve?.addLine(to: nextPoint)
                    } else {
                        curve = UIBezierPath()
                        curve?.move(to: nextPoint)
                        }
                    } else {
                        curve?.stroke()
                        curve = nil
                    }
            }
            curve?.stroke()
            //curve.move(to: CGPoint(x:bounds.minX, y: bounds.minY))
            //return curve
        }
        
        //let graph = pathForGraph()
        color.set()
        drawGraph()

    }
    
    
    func moveOrigin(byReactingTo panRecognizer: UIPanGestureRecognizer){
        let ofset = panRecognizer.translation(in: self)
        switch panRecognizer.state {
        case .changed:
            /*axesOriginOffset = CGPoint(x: axesOriginOffset.x+ofset.x, y: axesOriginOffset.y + ofset.y)*/
            axesOrigin = CGPoint(x: axesOrigin.x+ofset.x, y: axesOrigin.y + ofset.y)
            panRecognizer.setTranslation(CGPoint(x:0.0, y: 0.0), in: self)
        case .ended:
            axesOrigin = CGPoint(x: axesOrigin.x+ofset.x, y: axesOrigin.y + ofset.y)
            panRecognizer.setTranslation(CGPoint(x:0.0, y: 0.0), in: self)
            saveData()
        default:
            break
        }
    }
    
    func moveOriginToPoint(byReactingTo tapRecognizer: UITapGestureRecognizer) {
        axesOrigin = tapRecognizer.location(in: self)
        saveData()
    }
    
    

    override func draw(_ rect: CGRect) {
        if axesOrigin == nil {
            print("boom")
            axesOrigin = CGPoint(x: bounds.midX, y: bounds.midY + (navigationBarHeight ?? 0.0))
        }
        axesDrawer.drawAxes(in: bounds, origin: axesOrigin, pointsPerUnit: scale)
        //let curve = pathForGraph()
        if drawnFunction != nil {
            drawMathFunction(fx: drawnFunction!)
        }
    }
}

extension GraphView {
    func saveData() {
        if axesOrigin != nil {
            UserDefaults.standard.set(axesOrigin.x, forKey: "originX")
            UserDefaults.standard.set(axesOrigin.y, forKey: "originY")
            UserDefaults.standard.set(scale, forKey: "scale")
            print(axesOrigin)
        }
    }
    
    func loadData() {
        if let originX = UserDefaults.standard.value(forKey: "originX") as? CGFloat,
        let originY = UserDefaults.standard.value(forKey: "originY") as? CGFloat {
            axesOrigin = CGPoint( x: originX, y: originY)
            print(originX,originY,axesOrigin)
            setNeedsDisplay()
        }
        if let scale = UserDefaults.standard.value(forKey: "scale") as? CGFloat {
            self.scale = scale
        }
    }
}
