import { TasksPage } from './pages/TasksPage'
import { TimerPage } from './pages/TimerPage'
import { StatsPage } from './pages/StatsPage'
import { GoalsPage } from './pages/GoalsPage'

@Entry
@Component
struct App {
  @State current: number = 0
  private tabs: string[] = ['Tasks', 'Timer', 'Stats', 'Goals']

  build() {
    Column() {
      // Header
      Text('Study Tracker')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .padding({ top: 18, bottom: 8, left: 16, right: 16 })

      // Content（占满剩余空间，统一左右留白）
      Column() {
        if (this.current === 0) {
          TasksPage()
        } else if (this.current === 1) {
          TimerPage()
        } else if (this.current === 2) {
          StatsPage()
        } else {
          GoalsPage()
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 16, right: 16 })

      // Bottom Tabs（固定在底部）
      Row({ space: 8 }) {
        ForEach(this.tabs, (t: string, i: number) => {
          Button(t)
            .onClick(() => this.current = i)
            .backgroundColor(this.current === i ? '#2b6cff' : '#eaeaea')
            .fontColor(this.current === i ? '#ffffff' : '#333333')
            .padding(10)
            .borderRadius(16)
        })
      }
      .justifyContent(FlexAlign.Center)
      .padding({ left: 12, right: 12, bottom: 12, top: 8 })
    }
    .backgroundColor('#FFFFFF')
    .width('100%')
    .height('100%')
  }
}
