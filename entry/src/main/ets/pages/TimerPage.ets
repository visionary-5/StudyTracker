import { store } from '../data/Store'
import { Session } from '../data/types'

@Component
export struct TimerPage {
  @State mode: 'focus' | 'break' = 'focus'
  @State minutes: number = 25
  @State seconds: number = 0
  @State running: boolean = false
  private timerId: number | null = null

  private totalSeconds(): number { return this.minutes * 60 + this.seconds }
  private setFromTotal(sec: number) {
    this.minutes = Math.floor(sec / 60); this.seconds = sec % 60
  }

  start() {
    if (this.running) return
    this.running = true
    this.timerId = setInterval(() => {
      const left = this.totalSeconds() - 1
      if (left <= 0) {
        this.stop(true)
      } else {
        this.setFromTotal(left)
      }
    }, 1000)
  }

  stop(finished: boolean = false) {
    if (this.timerId) { clearInterval(this.timerId); this.timerId = null }
    const presetSec = (this.mode === 'focus' ? 25 : 5) * 60
    const usedSec = presetSec - this.totalSeconds()
    this.running = false

    if (finished) {
      const session: Session = {
        id: Date.now().toString(),
        startAt: Date.now(),
        durationMin: Math.max(1, Math.floor(usedSec / 60)),
        type: this.mode
      }
      store.addSession(session)
      // 切换模式并重置
      this.mode = this.mode === 'focus' ? 'break' : 'focus'
      this.resetPreset()
    }
  }

  resetPreset() {
    const preset = this.mode === 'focus' ? 25 : 5
    this.minutes = preset; this.seconds = 0
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Button('专注 25').onClick(() => { this.mode = 'focus'; this.resetPreset() })
        Button('休息 5').onClick(() => { this.mode = 'break'; this.resetPreset() })
      }
      .justifyContent(FlexAlign.Center)
      .padding({ top: 12, bottom: 12 })

      Text(`${this.minutes.toString().padStart(2,'0')}:${this.seconds.toString().padStart(2,'0')}`)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .padding({ top: 8, bottom: 8 })

      Row({ space: 12 }) {
        Button(this.running ? '暂停' : '开始')
          .onClick(() => this.running ? this.stop(false) : this.start())
        Button('重置').onClick(() => this.resetPreset())
      }
      .justifyContent(FlexAlign.Center)

      Text(this.mode === 'focus' ? '当前：专注番茄' : '当前：短休息')
        .fontColor('#666')
        .padding({ top: 8, bottom: 12 })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .onAppear(() => {
      // 出现时补一次状态
      if (!this.running && this.totalSeconds() === 0) {
        this.resetPreset()
      }
    })
  }
}
