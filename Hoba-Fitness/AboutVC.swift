import UIKit
import WebKit
import YandexMobileMetrica

final class AboutVC: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: ContentFittingWebView!
    
    let htmlContent = """
    <html>
    <head>
    <style>
    * {
    background: transparent;
    color: white;
    font-family: Arial, Helvetica, sans-serif;
    font-size: 20px;
    }
    
    ul {
    list-style: none;
    }
    
    ul li::before {
    content: "•";
    color: #B3D343;
    font-weight: bold;
    display: inline-block;
    width: 1em;
    margin-left: -1em;
    }
    
    a, .highlight {
    color: #B3D343 !important;
    }

    .highlight {
    color: #B3D343 !important;
    font-weight: bold !important;
    }
    
    #wrapper {
        display: table;
        table-layout: fixed;
        width: 100%;
        height: 450px;
    }
    #wrapper .divv {
        display: table-cell;
        height: 450px;
    }

    </style>
    </head>
    <body>
    <p>
    <span class="highlight">hoba</span> &mdash; это сеть небольших спортивных залов с круглосуточной работой всего в нескольких минутах ходьбы от вашего дома.
    </p>

    <p>
    <span class="highlight">БЕЗ ПЕРСОНАЛА</span> В зале нет администраторов и другого персонала, который может помешать Вам заниматься спортом. Все процессы максимально автоматизированы. Доступ в зал осуществляется с Вашего смартфона.
    </p>

    <p>
    <span class="highlight">БЕЗ ОЧЕРЕДЕЙ</span> Одновременно в зале может находиться ограниченное количество человек. Система бронирования времени тренировки &mdash; прекрасная возможность следить за загруженностью зала и выбирать комфортное время.
    </p>

    <p>
    <span class="highlight">НИЧЕГО ЛИШНЕГО</span> Наша главная цель &mdash; это открытие небольших залов с самым необходимым оборудованием для качественных занятий спортом. Фитнес &mdash; это фитнес, и ничего лишнего.
    </p>

    <p>
    <span class="highlight">ИНДИВИДУАЛЬНЫЙ ПОДХОД</span> Да, в нашем зале нет персонала в его классическом понимании, но у нас есть целая команда высококвалифицированных персноальных тренеров, который при Вашем желании проведут индивидуальные занятия по разным направлениям.
    </p>

    <div id="wrapper">
        <div class="divv" id="one" style="background: url(https://static.tildacdn.com/tild6661-3838-4266-b834-303037396634/_CIcR_39yDw.jpg) no-repeat; background-size: cover; border-right: 3px solid black;"></div>
        <div class="divv" id="two" style="background: url(https://static.tildacdn.com/tild3765-6264-4563-a334-353032316535/sIcL44QBwng.jpg) no-repeat; background-size: cover;"></div>
    </div>

    <center>
    <p style="font-size:24px;">
    Делай &laquo;<span class="highlight" style="font-size:24px; font-weight: bold;">hoba</span>&raquo;!
    </p>
    <p class="highlight">
    Остались вопросы?
    </p>
    <p>
    Напишите нам на сайте
    <br/>
    <b><a href="https://www.hoba.fit">www.hoba.fit</a></b>
    </p>
    
    <p style="font-size:12px;">
    ООО «ХОБА»
    <br/>
    Юридический и почтовый адрес: 664025, г. Иркутск, ул. Ленина, дом 6А, кв. 10
    </p>

    </center>
    </body>
    </html>
    """
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reportEvent("О проекте", [:])
        
        ///webView.navigationDelegate = self
    
        webView.navigationDelegate = self
        
        webView.isOpaque = false
        webView.scrollView.bounces = false
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        /// UI
        self.setMenuButton()
    }
    
    @IBAction func email(_ sender: Any) {
        let email = "hoba.fit@mail.ru"
        if let url = URL(string: "mailto:\(email)") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if navigationAction.navigationType == .linkActivated {
            guard let url = URL(string: "http://www.hoba.fit") else { return }
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        } else {
            print("not a user click")
            decisionHandler(.allow)
        }
    }
}
