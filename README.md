##### <i>~~모야가 모야?(실제로 한말)~~</i>

##### 이 레포지토리는 [ReactorKit](https://github.com/ReactorKit/ReactorKit)과 [Moya](https://github.com/Moya/Moya)를 사용하여 현재 온도와 4시간뒤 온도를 보여주는 예제입니다.
##### 본문에 ReactorKit과 Moya에 대한 설명과 작성한 코드가 첨부되어있습니다. 단, ReactorKit은 제가 작성한 다른 [레포지토리](https://github.com/kms0524/ReactorKit101)에 사용법과 설명이 있으니, 개념에 대한 설명은 하지않고 직접 작성한 방식에 대해서 이야기하도록 하겠습니다.
UI는 목업정도로만 구현하였으니 참고하세요. ~~참고 하라고 아 ㅋㅋ~~

# Moya

## What is Moya?
Moya는 [Alamofire](https://github.com/Alamofire/Alamofire)를 네트워크 계층을 구조화하는 방식을 할 수 있게 도와주는 라이브러리이다. 순정 Alamofire를 사용하다보면, 한번쯤 경험해봤을텐데 API호출과 같은 네트워크 통신이 필요한 모든곳에 AF.request 와 같이 호출 request 메소드를 모두 작성해봤어야 하는 경험이 있었을것이다. 소규모 프로젝트면 감당할 수 있겠지만, 만약 대규모 프로젝트라면? 네트워크 연결이 수십개가 필요하다면? 바로 이럴떄, 네트워크 계층을 구조화하여 조금 더 쉽게 연결을 도와줄 수 있는 라이브러리가, Moya 이다.

## Purpose
Moya의 목적은 [이곳](https://github.com/Moya/Moya/blob/master/Vision.md)에 있다. 간단히 요약하자면, 네트워크 요청과 관련된 에러를 줄이고, reactive extension을 제공하고, 사용하기 쉽게 만들어 주는것이 목적이다.

## Usage
Moya는 Proivder를 사용하여 네트워크 요청을 한다. 공식문서의 예제는 아래와 같다.

```swift
provider = MoyaProvider<GitHub>()
provider.request(.zen) { result in
    switch result {
    case let .success(moyaResponse):
        let data = moyaResponse.data
        let statusCode = moyaResponse.statusCode
        // do something with the response data or statusCode
    case let .failure(error):
        // this means there was a network failure - either the request
        // wasn't sent (connectivity), or no response was received (server
        // timed out).  If the server responds with a 4xx or 5xx error, that
        // will be sent as a ".success"-ful response.
    }
}
```

먼저, 열거형으로 사용할 네트워크 통신을 각각 선언해준다.

```swift
enum APIService {
    case currentWeather(lat: String, lon: String)
    case forecastWeather(lat: String, lon: String)
}
```

- currentWeather는 위도와 경도를 보내 해당 위치의 현재 날씨를 알려주는 요청이다.
- forecastWeather는 위도와 경도를 보내 해당 위치의 예상 날씨를 알려주는 요청이다.

이후, 각 네트워크 통신에 알맞은 네트워크 구조를 구축한다.

```swift
extension APIService: TargetType {

    var baseURL: URL { URL(string: BaseAPI.baseURL)!}
    
    var path: String {
        switch self {
        case .currentWeather(_, _) :
            return "weather"
        case .forecastWeather(_, _) :
            return "forecast"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .currentWeather, .forecastWeather :
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case let .currentWeather(lat, lon) :
            return .requestParameters(parameters: ["lat" : lat, "lon" : lon, "appid" : BaseAPI.apiKey, "units" : "metric"], encoding: URLEncoding.queryString)
        case let .forecastWeather(lat, lon):
            return .requestParameters(parameters: ["lat" : lat, "lon" : lon, "appid" : BaseAPI.apiKey, "units" : "metric"], encoding: URLEncoding.queryString)
        }
    }
    
    var headers: [String : String]? {
        return ["Content-type" : "application/json"]
    }
    
}
```
구추방식은 TargetType 프로토콜을 사용하여 구축해야한다.

TargetType은 baseURL, path, method, task, sampleData, haeders 를 사영해야한다.

- baseURL : 기초 URL으로, 모든 요처으이 기본으로 들어가게되는 주소를 작성하면 된다.
- path : 서브URL을 작성하면된다.
- method : 알맞은 CRUD를 작성하면 된다. 위에서 작성한 두 요청은 모두 .get 을 사용한다.
- task : 알맞은 요청 방식을 결정해야한다. 위도와 경도를 보내주어야 하기떄문에, 파라미터로 위도와 경도와 API키 그리고 온도의 단위를 화씨가 아닌 섭씨로 바꿔주는 "metric"을 보내주었다. 이후, 인코딩 방식까지 결정해햐줘야 한다.
- sampleData : 테스트시 올바른 값이 나왔는지 확인하는 용도로 작성하는 거지만, 생략해도 무방하다.
- headers : 올바른 http 헤더를 작성해야한다.

Response 모델을 아래와 같다.

```swift
struct CurrentWeatherModel: Codable {
    let main: Main
}
```


```swift
struct WetherForecastModel: Codable {
    let list: [List]
}

// MARK: - List
struct List: Codable {
    let main: Main
    let dtTxt: String

    enum CodingKeys: String, CodingKey {
        case main
        case dtTxt = "dt_txt"
    }
}
```


```swift
struct Main: Codable {
    let temp, tempMin, tempMax: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case tempMin = "temp_min"
        case tempMax = "temp_max"
    }
}
```

이제 ReactorKit을 활용해 요청하기만 하면 된다.

View의 구성은 아래와 같다.

```swift
import UIKit
import RxSwift
import RxCocoa
import ReactorKit
import RxViewController

class ViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    
    typealias Reactor = MainReactor
    
    var currentWeatherButton: UIButton = {
        var button = UIButton()
        button.setTitle("현재온도", for: .normal)
        button.backgroundColor = .red
        return button
    }()
    
    var forecastWeatherButton: UIButton = {
        var button = UIButton()
        button.setTitle("예상온도", for: .normal)
        button.backgroundColor = .blue
        return button
    }()
    
    var tempLabel: UILabel = {
        var label = UILabel()
        label.text = "temp"
        label.textColor = .red
        return label
    }()
    
    var tempMinLabel: UILabel = {
        var label = UILabel()
        label.text = "min"
        label.textColor = .red
        return label
    }()
    
    var tempMaxLabel: UILabel = {
        var label = UILabel()
        label.text = "max"
        label.textColor = .red
        return label
    }()
    
    var dtLabel: UILabel = {
        var label = UILabel()
        label.text = "asd"
        label.textColor = .red
        return label
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = .white
        
        view.addSubview(currentWeatherButton)
        view.addSubview(forecastWeatherButton)
        view.addSubview(tempLabel)
        view.addSubview(tempMinLabel)
        view.addSubview(tempMaxLabel)
        view.addSubview(dtLabel)
        self.reactor = MainReactor()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // subsview frame 설정
    }
    
    
    
    func bind(reactor: MainReactor) {
        bindAction(reactor)
        bindState(reactor)
    }
    
    func bindAction(_ reactor: MainReactor) {
        // Action 바인드
    }
    
    func bindState(_ reactor: MainReactor) {
        // State 바인드
        
    }
}
```

이제, 비즈니스 로직을 담당할 Reactor를 구성해보자.

우선 Reactor 프로토콜을 적용한 MainReactor 라는 클래스를 만들자.

```swift
class MainReactor: Reactor {

}
```

이후 Action, Mutation, State들과 disposeBag을 각각 선언해주고 State를 init 해주자.

```swift
class MainReactor: Reactor {

var disposeBag = DisposeBag()

enum Action {
        case tappedCurrentWeather //현재 온도 확인 버튼을 눌렀을 때의 Action
        case tappedForecastedWeather // 예상 온도 확인 버튼을 눌렀을 때의 Action
    }
    
    enum Mutation {
        case checkCurrentWeather(CurrentWeatherModel) // Api 호출을 통해 확인받은 현재 온도 값
        case checkForecastedWeather(WetherForecastModel) // Api 호출을 통해 확인받은 예상 온도 값
    }
    
    struct State {
        var isShowingForeacted: Bool = true // dt를 보여주기 위한 전달할 Bool 값, true는 보여주고 false는 보여주지 않게 설정했다.
        var temp, tempMin, tempMax: Double // View에 전달할 평균온도, 최저온도, 최고온도 값
        var dt: String // View에 전달할 시간 값
    }
    
    let initialState: State
    
    init() {
      self.initialState = State(temp: 0.0, tempMin: 0.0, tempMax: 0.0, dt: "")
    }
}
```
이후, mutate 함수를 통해, API 호출을 진행하자.

```swift
func mutate(action: Action) -> Observable<Mutation> {
  switch action { // 어떤 action인가?(현재 온도 확인 or 예상 온도 확인)
        case .tappedCurrentWeather: // 현재 온도
            let response = Observable<Mutation>.create { observer in // Api 호출을 통해 얻은 response는 mutate 함수의 return 값이 Observable<Mutaion> 이어야하기 떄문에, 빈 Observable을 생성하여 할당시킨다.
                let provider = MoyaProvider<APIService>() // Moya 를 사용하기 위해 provider를 선언.
                provider.request(.currentWeather(lat: "37.27", lon: "127.11")) { result in // 위도와 경도를 파라미터로 넘겨 request 한다. 
                    switch result {
                        
                    case let .success(response):
                        let result = try? response.map(CurrentWeatherModel.self) // 성공했을떄의 response를 모델에 알맞게 mapping 한 result를 선언한다.
                        observer.onNext(Mutation.checkCurrentWeather(result ?? CurrentWeatherModel(main: Main(temp: 0.0, tempMin: 0.0, tempMax: 0.0)))) // response 옵저버에 result를 전달하여 mutation에 전달받은 값들을 할당시킨다.
                        observer.onCompleted()
                    case let .failure(error):
                        observer.onError(error)
                        
                    }
                }
                return Disposables.create()
            }
            return response
            // 예사 온도 또한 위와 동일하다.
        case .tappedForecastedWeather:
            let response = Observable<Mutation>.create { observer in
                let provider = MoyaProvider<APIService>()
                provider.request(.forecastWeather(lat: "37.27", lon: "127.11")) { result in
                    switch result {
                        
                    case let .success(response):
                        let result = try? response.map(WetherForecastModel.self)
                        observer.onNext(Mutation.checkForecastedWeather(result ?? WetherForecastModel(list: [])))
                    case let .failure(error):
                        observer.onError(error)
                        
                    }
                }
                return Disposables.create()
            }
            return response
        }
}
```

이제 Mutation에 전달된 값들을 reduce를 통해 View로 전달하자.

```swift
func reduce(state: State, mutation: Mutation) -> State {
        
        var newState = state // 새로운 상태를 기존 상태에 덮어쓴 상태로 선언
        
        switch mutation {
        case .checkCurrentWeather(let currentWeatherModel):
        // mutate의 Observable에서 방출된 값들을 새로운 상태에 할당해주기
            newState.temp = currentWeatherModel.main.temp
            newState.tempMin = currentWeatherModel.main.tempMin
            newState.tempMax = currentWeatherModel.main.tempMax
            newState.isShowingForeacted = true
        case .checkForecastedWeather(let wetherForecastModel):
            newState.temp = wetherForecastModel.list[0].main.temp
            newState.tempMin = wetherForecastModel.list[0].main.tempMin
            newState.tempMax = wetherForecastModel.list[0].main.tempMax
            newState.dt = wetherForecastModel.list[0].dtTxt
            newState.isShowingForeacted = false // 현재 상태가 예상 온도를 보여주는 상태일시, isHidden에 할당할 bool 값
        }
        
        return newState
    }

```
다시 View로 돌아와, bind를 구성하자.

```swift
func bindAction(_ reactor: MainReactor) {
        
        // 뷰가 나타날시, 최초화면은 현재 온도를 보여주는 화면으로 설정하였다.
        self.rx.viewWillAppear
            .subscribe(onNext: {_ in
                reactor.action.onNext(.tappedCurrentWeather)
            })
            .disposed(by: disposeBag)
        
        currentWeatherButton.rx.tap
            .subscribe(onNext: {
                reactor.action.onNext(.tappedCurrentWeather)
            })
            .disposed(by: disposeBag)
        
        forecastWeatherButton.rx.tap
            .subscribe(onNext: {
                reactor.action.onNext(.tappedForecastedWeather)
            })
            .disposed(by: disposeBag)
    }
    
    func bindState(_ reactor: MainReactor) {
        
        // 예상 온도를 보여줄시, 해당 시간을 보여주는 label을 isHidden 할지 안할지 결정 하였다.
        reactor.state.map {
            $0.isShowingForeacted
        }
        .bind(to: dtLabel.rx.isHidden)
        .disposed(by: disposeBag)
        
        reactor.state.map  {
            String("\($0.dt) 시의 예상 기온")
        }
        .bind(to: dtLabel.rx.text)
        .disposed(by: disposeBag)
        
        reactor.state.map {
            String("온도 : \($0.temp)")
        }
        .bind(to: tempLabel.rx.text)
        .disposed(by: disposeBag)
        
        reactor.state.map {
            String("최고 온도 : \($0.tempMax)")
        }
        .bind(to: tempMaxLabel.rx.text)
        .disposed(by: disposeBag)
        
        reactor.state.map {
            String("최저 온도 : \($0.tempMin)")
        }
        .bind(to: tempMinLabel.rx.text)
        .disposed(by: disposeBag)
    }
    
```
![Simulator Screen Recording - iPhone 13 Pro - 2022-09-28 at 19 20 13](https://user-images.githubusercontent.com/48994081/192755195-45e31c46-d8c7-4fae-829f-0127f33b5367.gif)

