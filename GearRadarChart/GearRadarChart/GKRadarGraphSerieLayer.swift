// The MIT License (MIT)
//
// Copyright (c) 2015 pascaljette
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import UIKit

/// Layer that draws a serie in the radar graph.
internal class GKRadarGraphSerieLayer: CAShapeLayer {
    
    //
    // MARK: Initialization
    //
    
    /// Parameterless constructor.
    override init() {
        super.init()

        doInit()
    }
    
    /// Required initializer with coder.
    ///
    /// - param coder The coder used to initialize.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        doInit()
    }
    
    /// Common setup function
    fileprivate func doInit() {
     
        // Default is false, meaning the layer is not re-drawn when its bounds change.
        needsDisplayOnBoundsChange = true
        
        let decorationLayer = GKRadarGraphSerieDecorationLayer()
        decorationLayer.frame = self.bounds
        
        self.decorationLayer = decorationLayer
        lineJoin = "bevel"
    }
    
    //
    // MARK: Stored properties
    //
    
    /// Global data source
    var parameterDatasource: GKRadarGraphParameterDatasource?
    
    /// Serie containing the data and draw info for this layer.
    var serie: GKRadarGraphView.Serie? {
        
        didSet {
            
            if let serieFillMode = serie?.fillMode {
                
                switch serieFillMode {
                    
                case .none:
                    fillColor = nil
                    
                case .solid(let color):
                    fillColor = color.cgColor
                }

            } else {
                
                fillColor = nil
            }
            
            strokeColor = serie?.strokeColor?.cgColor
            lineWidth = serie?.strokeWidth ?? 1
            
            decorationLayer?.serie = serie
        }
    }

    /// A reference on the next layer in the series queue.
    weak var nextSerieLayer: GKRadarGraphSerieLayer?
    
    /// Index of the last animated vertex.  Useful for chaining animations on vertices.
    internal var lastAnimatedVertexIndex: Int = 0
    
    /// Animation type for the serie
    internal var animationType: GKRadarGraphView.SeriesAnimation = .none
}

extension GKRadarGraphSerieLayer {
    
    //
    // MARK: Computed properties
    //
    
    /// Array of parameters to generate the graph.
    fileprivate var parameters: [GKRadarGraphView.Parameter] {
        
        return parameterDatasource?._parameters ?? []
    }
    
    /// Center of the graph's circle.  The circle is used to draw the regular polygons inside.
    fileprivate var circleCenter: CGPoint {
        return parameterDatasource?._circleCenter ?? CGPoint.zero
    }
    
    /// Radius of the circle.  Will be the full radius for the outer polygon and a smaller
    /// radius for the inner gradations.
    fileprivate var circleRadius: CGFloat {
        return parameterDatasource?._circleRadius ?? 0
    }
    
    /// Whenever we set the frame for the series layer, we need to propagate the change to
    /// the decoration layer.
    override var frame: CGRect {
        
        get {
            
            return super.frame
        }
        
        set {
            
            super.frame = newValue
            decorationLayer?.frame = newValue
        }
    }
    
    /// A reference on the sublayer that draws the decorations.
    var decorationLayer: GKRadarGraphSerieDecorationLayer? {
        
        get {
            
            guard let sublayersInstance = self.sublayers else {
                
                return nil
            }
            
            // Return the first sublayer that is of type GKRadarGraphSerieDecorationLayer
            // There should be just one in any case.
            
            let myLayer = sublayersInstance.filter( { return $0 is GKRadarGraphSerieDecorationLayer })
            return myLayer.first as? GKRadarGraphSerieDecorationLayer
        }
        
        set {

            // Get an array, but in all cases, there should be only one of those sublayers.
            let decorationLayers = sublayers?.filter({ $0 is GKRadarGraphSerieDecorationLayer})
            
            guard let newSublayerInstance = newValue else {
                
                decorationLayers?.forEach({ $0.removeFromSuperlayer()})
                
                return
            }
            
            if let currentDecorationLayer = decorationLayers?.first as? GKRadarGraphSerieDecorationLayer {
                
                currentDecorationLayer.frame = newSublayerInstance.frame
                currentDecorationLayer.serie = newSublayerInstance.serie
                currentDecorationLayer.setNeedsDisplay()
            
            } else {
                
                newSublayerInstance.parameterDatasource = parameterDatasource
                newSublayerInstance.setNeedsDisplay()
                addSublayer(newSublayerInstance)
            }
        }
    }
}

extension GKRadarGraphSerieLayer {
    
    //
    // MARK: Drawing functions
    //

    /// Draw a serie in the radar chart.
    ///
    /// - parameter ctx The context in which to draw the serie.
    /// - parameter serie; The serie containing all the info to render.
    internal func generatePath() {
        
        guard let serieInstance = serie else {
            
            return
        }
        
        let outerVertices = parameters.flatMap( { return $0.outerVertex?.point })
        
        guard !outerVertices.isEmpty else {
            
            return
        }
        
        let bezierPath: UIBezierPath = UIBezierPath()
        var allSerieVertices: [CGPoint] = []
        
        outerVertices.enumerated().forEach { (offset, vertex) in
        
            let differenceX = vertex.x - circleCenter.x
            let differenceY = vertex.y - circleCenter.y
            
            // scalar multiplication
            let scalarMultiplier = serieInstance.percentageValues.count > offset
                ? serieInstance.percentageValues[offset]
                : 0
            
            let pointX = circleCenter.x + (differenceX * scalarMultiplier)
            let pointY = circleCenter.y + (differenceY * scalarMultiplier)
            
            let vertex: CGPoint = CGPoint(x: pointX, y: pointY)
            
            allSerieVertices.append(vertex)
            
            if offset == 0 {
                bezierPath.move(to: vertex)
            } else {
                bezierPath.addLine(to: vertex)
            }
        }
        
        self.serie?.vertices = allSerieVertices
        
        bezierPath.close()
        
        self.path = bezierPath.cgPath
    }
}

extension GKRadarGraphSerieLayer {
    
    //
    // MARK: Animation methods
    //
    
    /// Make a scale animation that will grow the serie from nothing to its full scale.
    ///
    /// - parameter duration: Duration of the scale animation.
    ///
    /// - returns: A scale animation that can be applied to the layer using addAnimation.
    internal func makeScaleAnimation(_ duration: CGFloat) {
        
        let fromPath: UIBezierPath = UIBezierPath()
        let toPath: UIBezierPath = UIBezierPath()
        
        serie?.vertices.enumerated().forEach { (offset, vertex) in
        
            if offset == 0 {
                fromPath.move(to: circleCenter)
                toPath.move(to: vertex)
            } else {
                fromPath.addLine(to: circleCenter)
                toPath.addLine(to: vertex)
            }
        }
        
        fromPath.close()
        toPath.close()
        
        addAnimationFromPath(fromPath.cgPath, toPath: toPath.cgPath, duration: CFTimeInterval(duration))
    }
    
    /// Make a path animation for the serie where it will expand parameter by parameter.
    /// The idea is to have the path start with all points at 0 and then expand each point
    /// one by one.
    ///
    /// - parameter duration: Duration of the animation (for 1 point, not the full animation).
    ///
    /// - returns: A scale animation that can be applied to the layer using addAnimation.
    internal func makeParameterPathAnimation(_ duration: CGFloat) {
        
        guard let serieInstance = serie else {
            
            return
        }
        
        let fromPath: UIBezierPath = UIBezierPath()
        let toPath: UIBezierPath = UIBezierPath()
        
        // Make an all-zero path
        serieInstance.vertices.enumerated().forEach { (offset, vertex) in
            let fromPoint: CGPoint = offset < lastAnimatedVertexIndex
                ? vertex
                : circleCenter
            
            let toPoint: CGPoint = offset < lastAnimatedVertexIndex + 1
                ? vertex
                : circleCenter
            
            if offset == 0 {
                
                fromPath.move(to: fromPoint)
                toPath.move(to: toPoint)
                
            } else {
                
                fromPath.addLine(to: fromPoint)
                toPath.addLine(to: toPoint)
            }

        }

        fromPath.close()
        toPath.close()
        
        addAnimationFromPath(fromPath.cgPath, toPath: toPath.cgPath, duration: CFTimeInterval(duration))
    }
    
    /// Make a path animation based on the provided paths an durations.  This can be used
    /// to scale or animate the shape construction.
    ///
    /// - parameter fromPath: Initial path.
    /// - parameter toPath: Destination path.
    /// - parameter duration: Animation duration.
    fileprivate func addAnimationFromPath(_ fromPath: CGPath, toPath: CGPath, duration: CFTimeInterval) {
        
        let pathAnimation = CABasicAnimation(keyPath: "path")
        
        pathAnimation.fromValue = fromPath
        pathAnimation.toValue = toPath
        pathAnimation.duration = CFTimeInterval(duration)
        pathAnimation.isRemovedOnCompletion = false
        pathAnimation.fillMode = kCAFillModeForwards
        pathAnimation.delegate = self
        pathAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        add(pathAnimation, forKey: "path")
    }
}

extension GKRadarGraphSerieLayer: CAAnimationDelegate {
    
    //
    // MARK: CAAnimationDelegate implementation
    //
    
    /// Called when an animation on this layer stops.
    ///
    /// - parameter anim: Instance of the animation that just stopped.
    /// - parameter finished: Whether the animation is finished or was interrupted.
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        
        guard flag else {
            
            isHidden = false
            decorationLayer?.isHidden = false
            
            removeAllAnimations()
            
            var currentLayer = self
            while let nextLayer = currentLayer.nextSerieLayer {
                
                nextLayer.isHidden = false
                nextLayer.decorationLayer?.isHidden = false
                
                nextLayer.removeAllAnimations()
                
                currentLayer = nextLayer
            }
            
            return
        }
        
        switch animationType {
            
        case .parameterByParameter(let duration):
            lastAnimatedVertexIndex += 1
            
            if lastAnimatedVertexIndex < serie?.vertices.count ?? 0 {
                makeParameterPathAnimation(duration)
            } else if lastAnimatedVertexIndex == serie?.vertices.count {
                decorationLayer?.isHidden = false
                
                if let nextLayerInstance = nextSerieLayer {
                    nextLayerInstance.isHidden = false
                    nextLayerInstance.makeParameterPathAnimation(duration)
                }
            }
            
        case .scaleOneByOne(let duration):
            
            decorationLayer?.isHidden = false

            if let nextLayerInstance = nextSerieLayer {
                
                nextLayerInstance.isHidden = false
                nextLayerInstance.makeScaleAnimation(duration)
            }
            
        case .scaleAll:
            decorationLayer?.isHidden = false
            
        case .none:
            break
        }
    }
}


extension GKRadarGraphSerieLayer {
    
    //
    // MARK: CALayer overrides
    //
    
    /// Override set needs display in order to redraw the children layers
    /// when the parent view is changed.
    override func setNeedsDisplay() {
        
        super.setNeedsDisplay()
        
        // For all sublayers (typically series layers), redraw as well.
        for sublayer in sublayers ?? [] {
            
            sublayer.setNeedsDisplay()
        }
    }
}


