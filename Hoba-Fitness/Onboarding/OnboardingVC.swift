import UIKit

final class OnboardingVC: UIViewController, UIScrollViewDelegate {
    
    var parentVC: GenderSelectorVC?
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
        }
    }
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    var slides:[Slide] = [];
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        slides = createSlides()
        setupSlideScrollView(slides: slides)
        
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
        view.bringSubviewToFront(pageControl)        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func createSlides() -> [Slide] {
        let slide0:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide0.imageView.image = UIImage(named: "onboard0")
        slide0.labelTitle.text = "ВЫБИРАЙ"
        slide0.labelDesc.text = "Абонементы, индивидуальные тренировки или разовые занятия? Хотите познакомиться с залом бесплатно? Бронируйте бесплатную тренировку."
        slide0.labelButton.addTarget(self, action: #selector(action), for: UIControl.Event.touchUpInside)
        
        let slide1:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide1.imageView.image = UIImage(named: "onboard1")
        slide1.labelTitle.text = "РЕГИСТРИРУЙСЯ"
        slide1.labelDesc.text = "Регистрируйся, чтобы открыть доступ в зал. Регистрация бесплатна."
        slide1.labelButton.addTarget(self, action: #selector(action), for: UIControl.Event.touchUpInside)
        
        let slide2:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide2.imageView.image = UIImage(named: "onboard2")
        slide2.labelTitle.text = "ПЛАНИРУЙ"
        slide2.labelDesc.text = "Выбери удобную дату и время для занятия. Следи за загруженностью зала - в зале одновременно могут заниматься 8 человек."
        slide2.labelButton.addTarget(self, action: #selector(action), for: UIControl.Event.touchUpInside)

        let slide3:Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide3.imageView.image = UIImage(named: "onboard3")
        slide3.labelTitle.text = "КОНТРОЛИРУЙ"
        slide3.labelDesc.text = "Поменялись планы? Не проблема! Можешь отменить или перенести свою тренировку."
        slide3.labelButton.tag = 1
        slide3.labelButton.setTitle("Смотреть залы", for: .normal)
        slide3.labelButton.addTarget(self, action:#selector(action), for: .touchUpInside)

        return [slide0, slide1, slide2, slide3]
    }
    
    @objc func action(sender: UIButton!) {
        if sender.tag == 1 {
            App.this.onboardingWasShown = true
            ///self.dismiss(animated: true, completion: nil)
            self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
        }
        else {
            let offset = self.view.frame.width * CGFloat(pageControl.currentPage + 1)
            scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
        }
    }
    
    func setupSlideScrollView(slides : [Slide]) {
        scrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: view.frame.height)
        scrollView.isPagingEnabled = true
        
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
            scrollView.addSubview(slides[i])
        }
    }
    
    /*
     * default function called when view is scolled. In order to enable callback
     * when scrollview is scrolled, the below code needs to be called:
     * slideScrollView.delegate = self or
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView.contentOffset.y != 0 { // horizontal lock
            scrollView.contentOffset.y = 0
        }
        
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        pageControl.currentPage = Int(pageIndex)
        
        let maximumHorizontalOffset: CGFloat = scrollView.contentSize.width - scrollView.frame.width
        let currentHorizontalOffset: CGFloat = scrollView.contentOffset.x
        
        // vertical
        let maximumVerticalOffset: CGFloat = scrollView.contentSize.height - scrollView.frame.height
        let currentVerticalOffset: CGFloat = scrollView.contentOffset.y
        
        let _: CGFloat = currentHorizontalOffset / maximumHorizontalOffset
        let _: CGFloat = currentVerticalOffset / maximumVerticalOffset
    }
    
    func scrollView(_ scrollView: UIScrollView, didScrollToPercentageOffset percentageHorizontalOffset: CGFloat) {
        if (pageControl.currentPage == 0) {
            //Change background color to toRed: 103/255, fromGreen: 58/255, fromBlue: 183/255, fromAlpha: 1
            //Change pageControl selected color to toRed: 103/255, toGreen: 58/255, toBlue: 183/255, fromAlpha: 0.2
            //Change pageControl unselected color to toRed: 255/255, toGreen: 255/255, toBlue: 255/255, fromAlpha: 1
            
            let pageUnselectedColor: UIColor = fade(fromRed: 255/255, fromGreen: 255/255, fromBlue: 255/255, fromAlpha: 1, toRed: 103/255, toGreen: 58/255, toBlue: 183/255, toAlpha: 1, withPercentage: percentageHorizontalOffset * 3)
            pageControl.pageIndicatorTintColor = pageUnselectedColor
            
            
            let bgColor: UIColor = fade(fromRed: 103/255, fromGreen: 58/255, fromBlue: 183/255, fromAlpha: 1, toRed: 255/255, toGreen: 255/255, toBlue: 255/255, toAlpha: 1, withPercentage: percentageHorizontalOffset * 3)
            slides[pageControl.currentPage].backgroundColor = bgColor
            
            let pageSelectedColor: UIColor = fade(fromRed: 81/255, fromGreen: 36/255, fromBlue: 152/255, fromAlpha: 1, toRed: 103/255, toGreen: 58/255, toBlue: 183/255, toAlpha: 1, withPercentage: percentageHorizontalOffset * 3)
            pageControl.currentPageIndicatorTintColor = pageSelectedColor
        }
    }
    
    func fade(fromRed: CGFloat, fromGreen: CGFloat, fromBlue: CGFloat, fromAlpha: CGFloat, toRed: CGFloat, toGreen: CGFloat,
              toBlue: CGFloat, toAlpha: CGFloat, withPercentage percentage: CGFloat) -> UIColor {
        
        let red: CGFloat = (toRed - fromRed) * percentage + fromRed
        let green: CGFloat = (toGreen - fromGreen) * percentage + fromGreen
        let blue: CGFloat = (toBlue - fromBlue) * percentage + fromBlue
        let alpha: CGFloat = (toAlpha - fromAlpha) * percentage + fromAlpha
        
        // return the fade colour
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
 
}


