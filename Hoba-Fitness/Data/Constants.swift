import UIKit

let coachHours: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

let LEAVE_ROOM = "Выход из зала"
let LEAVE_ROOM_MSG = "Тренировка будет завершена и списана. Вы хотите выйти из зала?"

let BTN_CONFIRM = "Да, хочу"
let BTN_CANCEL = "Нет, не надо"

let OPENING_DOOR = "Открываем..."

let TRAIN_CANCEL = "Отмена тренировки"
let TRAIN_CANCEL_SENT_MSG = "Запрос на отмену тренировки отправлен. Средства будут возвращены в соответствии с правилами."

/// Train types
let TARIFF_NOT_SET = 0
let TARIFF_FREE = 0

let TARIFF_SINGLE_TRAIN = 1
let TARIFF_YEAR_PLAN = 2
let TARIFF_TRAINS_W_COACH = 3
let TARIFF_PACKAGE = 4
let TARIFF_ABONEMENT = 5

/// Sizing
let COUNTERDIAGRAMWIDTH = 270

/// Time units
let MIN_1 = 60
let MIN_2 = MIN_1 * 2
let MIN_10 = MIN_1 * 10
let MIN_30 = MIN_1 * 30
let MIN_60 = MIN_1 * 60
let MIN_70 = MIN_1 * 70
let MIN_80 = MIN_1 * 80
let MIN_90 = MIN_1 * 90
let MIN_110 = MIN_1 * 110
let DAY_1 = MIN_1 * 60 * 24

let TIMEWEARBEFORE = MIN_10
let TIMEWEARAFTER = MIN_10
let TIMETRAIN = MIN_60
let TIMEFULLPERIOD = MIN_10 + MIN_60 + MIN_10

let FILL_PERCENTAGE_60: CGFloat = 10.8
let FILL_PERCENTAGE_90: CGFloat = 9.3
let TIMEPERIOD = 600 // 10 min

let ONEHALFDAY = 25 * 60 * 60

/// Colors
let colorTrainWaiting = UIColor(argb: 0xff01B3FF)
let colorTrainFirstChange = UIColor(argb: 0xffffb41c)
let colorTrainTime = UIColor(argb: 0xffb3d343)
let colorTrainCloseToEnd = UIColor(argb: 0xffced343)
let colorTrainNotFinished = UIColor(argb: 0xffff9600)

let colorInactiveYellow = UIColor(argb: 0xff604610)
let colorActiveYellow = UIColor(argb: 0xffFFB41C)
let colorInactiveGreen = UIColor(argb: 0xff314111)
let colorActiveGreen = UIColor(argb: 0xffB3D343)
