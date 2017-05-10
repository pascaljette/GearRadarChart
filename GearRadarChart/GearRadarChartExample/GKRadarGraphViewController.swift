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

import UIKit
import GearRadarChart

/// Stored properties
class GKRadarGraphViewController: UIViewController {
    
    //
    // MARK: Nested types
    //
    enum AnimationPickerType: String {
        
        /// Scale all series simultaneously.
        case scaleAll = "Scale all"
        
        /// Scale series one by one.
        case scaleOneByOne = "Scale one by one"
        
        /// Parameter one by one.
        case parameterByParameter = "Parameter one by one"
        
        /// Get the corresponding series animation enum from the picker data.
        var seriesAnimation: GKRadarGraphView.SeriesAnimation {
            
            switch self {
                
            case .scaleAll:
                return .scaleAll(GKRadarGraphViewController.ANIMATION_DEFAULT_DURATION)
                
            case .scaleOneByOne:
                return .scaleOneByOne(GKRadarGraphViewController.ANIMATION_DEFAULT_DURATION)
                
            case .parameterByParameter:
                return .parameterByParameter(GKRadarGraphViewController.ANIMATION_DEFAULT_DURATION)
            }
        }
    }
    
    //
    // MARK: IBOutlets
    //
    
    @IBOutlet weak var radarGraphView: GKRadarGraphView!

    //
    // MARK: Stored properties
    //
    
    /// Model containing info about generating the graph.
    let model: GKRadarGraphModel
    
    /// Animation picker view data
    let pickerViewData: [AnimationPickerType] = [.scaleAll, .scaleOneByOne, .parameterByParameter]
    
    //
    // MARK: Initialisation.
    //
    
    /// Initialise with a model.
    ///
    /// - parameter model: Model to use to initialise the view controller.
    init(model: GKRadarGraphModel) {
        
        self.model = model
        super.init(nibName: "GKRadarGraphViewController", bundle: nil)
    }

    /// Required initialiser with a coder.
    /// We generate a fatal error to underline the fact that we do not want to support storyboards.
    ///
    /// - parameter coder: Coder used to serialize the object.
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

extension GKRadarGraphViewController {
    
    //
    // MARK: Class variables.
    //
    
    /// Default duration for an animation.
    class var ANIMATION_DEFAULT_DURATION: CGFloat {
        return 0.4
    }
}

extension GKRadarGraphViewController {
    
    //
    // MARK: UIViewController overrides.
    //

    /// View did load
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.navigationItem.title = "GKRadarGraph"
    }
    
    /// View will appear.
    ///
    /// - parameter animated: Whether the view should be animated.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        radarGraphView.parameters = model.parameters
        radarGraphView.backgroundColor = UIColor(red: 0, green: 200/255, blue: 100/255, alpha: 150/255)
        
        radarGraphView.series = model.series
    }
}

extension GKRadarGraphViewController: UIPickerViewDataSource {
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return pickerViewData.count
    }
}

extension GKRadarGraphViewController: UIPickerViewDelegate {
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerViewData[row].rawValue
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let selection = pickerViewData[row]
        radarGraphView.animateWithType(selection.seriesAnimation)
    }
}


extension GKRadarGraphViewController {
    
    //
    // MARK: IBAction.
    //

    /// Animate button tapped.
    ///
    /// - parameter sender: The "Animate" button itself.
    @IBAction func animateButtonTapped(_ sender: AnyObject) {
        
        let alertController: UIAlertController = UIAlertController(title: "Select Animation", message: nil, preferredStyle: .actionSheet)
     
        // TODO-pk there is a better to do this than this ugly enum.
        let scaleAllAction: UIAlertAction = UIAlertAction(title: AnimationPickerType.scaleAll.rawValue, style: .default, handler: { [weak self] _ in
            
            guard let strongSelf = self else {
                
                return
            }
            
            let action = AnimationPickerType.scaleAll
            strongSelf.radarGraphView.animateWithType(action.seriesAnimation)
            
        })
        
        let scaleOneByOneAction: UIAlertAction = UIAlertAction(title: AnimationPickerType.scaleOneByOne.rawValue, style: .default, handler: { [weak self] _ in
            
            guard let strongSelf = self else {
                
                return
            }
            
            let action = AnimationPickerType.scaleOneByOne
            strongSelf.radarGraphView.animateWithType(action.seriesAnimation)
            
        })
        
        let parameterOneByOneAction: UIAlertAction = UIAlertAction(title: AnimationPickerType.parameterByParameter.rawValue, style: .default, handler: { [weak self] _ in
            
            guard let strongSelf = self else {
                
                return
            }
            
            let action = AnimationPickerType.parameterByParameter
            strongSelf.radarGraphView.animateWithType(action.seriesAnimation)
            
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(scaleAllAction)
        alertController.addAction(scaleOneByOneAction)
        alertController.addAction(parameterOneByOneAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
}
