import UIKit
import WebKit

final class ContentFittingWebView: WKWebView {
    
    var contentSizeObservationToken: NSKeyValueObservation?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        startObservingHeight()
    }
    
    override var intrinsicContentSize: CGSize {
        return scrollView.contentSize
    }
    
    func startObservingHeight() {
        contentSizeObservationToken?.invalidate()
        contentSizeObservationToken = scrollView.observe(\UIScrollView.contentSize, options: [.new], changeHandler: { (scrollView, change) in
            self.invalidateIntrinsicContentSize()
        })
    }
}
