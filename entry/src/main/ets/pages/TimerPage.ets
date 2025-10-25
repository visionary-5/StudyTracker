import { store } from '../data/Store'
import { Session, Task } from '../data/types'

function pad2(n: number): string { return n < 10 ? ('0' + n) : '' + n }

@Component
export struct TimerPage {
  @State mode: 'focus' | 'break' = 'focus'
  @State minutes: number = 25
  @State seconds: number = 0
  @State running: boolean = false
  @State private selectedTaskIndex: number = -1

  private startAt: number = 0
  private targetAt: number = 0
  private initialTotalSec: number = 25 * 60
  private timerId: number = 0
  private speed: number = 1

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private ringSize: number = 220

  private presetSec(): number { return this.mode === 'focus' ? 25 * 60 : 5 * 60 }
  private totalSeconds(): number { return this.minutes * 60 + this.seconds }
  private setFromTotal(sec: number): void {
    const s = Math.max(0, sec)
    this.minutes = Math.floor(s / 60)
    this.seconds = s % 60
  }
  private getLeftSec(): number {
    if (!this.running || !this.targetAt) return this.totalSeconds()
    const leftMs = this.targetAt - Date.now()
    return Math.max(0, Math.ceil(leftMs / 1000))
  }

  private drawRing(): void {
    const w = this.ringSize
    const h = this.ringSize
    const ctx = this.ctx
    const cx = w / 2
    const cy = h / 2
    const r = (this.ringSize - 16) / 2
    const left = this.getLeftSec()
    const total = this.initialTotalSec > 0 ? this.initialTotalSec : this.presetSec()
    const progress = total > 0 ? Math.min(1, 1 - left / total) : 0

    ctx.clearRect(0, 0, w, h)
    ctx.beginPath(); ctx.strokeStyle = '#e6eaf2'; ctx.lineWidth = 12
    ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()

    ctx.beginPath()
    ctx.strokeStyle = this.mode === 'focus' ? '#2b6cff' : '#34c759'
    ctx.lineWidth = 12
    const start = -Math.PI / 2
    const end = start + progress * Math.PI * 2
    ctx.arc(cx, cy, r, start, end); ctx.stroke()
  }

  private tick(): void {
    if (!this.running) return
    const left = this.getLeftSec()
    if (left <= 0) this.finish()
    else { this.setFromTotal(left); this.drawRing() }
  }

  private applyPreset(): void {
    const sec = this.presetSec()
    this.initialTotalSec = sec
    this.setFromTotal(sec)
    this.drawRing()
  }

  start(): void {
    if (this.running) return
    const left = this.totalSeconds() === 0 ? this.presetSec() : this.totalSeconds()
    this.initialTotalSec = left
    const now = Date.now()
    this.startAt = now
    this.targetAt = now + Math.round((left * 1000) / this.speed)
    this.running = true
    this.timerId = setInterval(() => this.tick(), 500)
  }

  pause(): void {
    if (!this.running) return
    if (this.timerId) { clearInterval(this.timerId); this.timerId = 0 }
    const left = this.getLeftSec()
    this.setFromTotal(left)
    this.running = false
    this.startAt = 0
    this.targetAt = 0
    this.drawRing()
  }

  finish(): void {
    if (this.timerId) { clearInterval(this.timerId); this.timerId = 0 }
    const endAt = Date.now()
    const usedSec = this.startAt > 0 ? Math.max(0, Math.round((endAt - this.startAt) / 1000) * this.speed)
      : (this.initialTotalSec - this.totalSeconds())
    this.running = false
    this.startAt = 0
    this.targetAt = 0

    const session: Session = {
      id: Date.now().toString(),
      startAt: endAt - usedSec * 1000,
      durationMin: Math.max(1, Math.floor(usedSec / 60)),
      type: this.mode,
      taskId: this.getSelectedTaskId()
    }
    store.addSession(session)

    this.mode = (this.mode === 'focus') ? 'break' : 'focus'
    this.applyPreset()
  }

  stop(): void {
    if (this.timerId) { clearInterval(this.timerId); this.timerId = 0 }
    this.running = false
    this.startAt = 0
    this.targetAt = 0
    this.applyPreset()
  }

  private getTaskList(): Task[] { return store.tasks }
  private getTaskCount(): number { return this.getTaskList().length }
  private getSelectedTaskId(): string | undefined {
    const ts = this.getTaskList()
    return (this.selectedTaskIndex >= 0 && this.selectedTaskIndex < ts.length) ? ts[this.selectedTaskIndex].id : undefined
  }
  private getSelectedTaskTitle(): string {
    const ts = this.getTaskList()
    return (this.selectedTaskIndex >= 0 && this.selectedTaskIndex < ts.length) ? ts[this.selectedTaskIndex].title : '未选择（可选）'
  }
  private nextTask(): void {
    const n = this.getTaskCount()
    if (n <= 0) { this.selectedTaskIndex = -1; return }
    if (this.selectedTaskIndex < 0) { this.selectedTaskIndex = 0; return }
    this.selectedTaskIndex = (this.selectedTaskIndex + 1) % n
  }
  private prevTask(): void {
    const n = this.getTaskCount()
    if (n <= 0) { this.selectedTaskIndex = -1; return }
    if (this.selectedTaskIndex < 0) { this.selectedTaskIndex = n - 1; return }
    this.selectedTaskIndex = (this.selectedTaskIndex - 1 + n) % n
  }

  aboutToAppear(): void { this.applyPreset() }
  aboutToDisappear(): void { if (this.timerId) { clearInterval(this.timerId); this.timerId = 0 } }

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Button('专注 25').onClick(() => { if (!this.running) { this.mode = 'focus'; this.applyPreset() } })
          .backgroundColor(this.mode === 'focus' ? '#2b6cff' : '#eaeaea')
          .fontColor(this.mode === 'focus' ? '#fff' : '#333')
        Button('休息 5').onClick(() => { if (!this.running) { this.mode = 'break'; this.applyPreset() } })
          .backgroundColor(this.mode === 'break' ? '#34c759' : '#eaeaea')
          .fontColor(this.mode === 'break' ? '#fff' : '#333')
      }
      .justifyContent(FlexAlign.Center)
      .padding({ top: 8 })

      if (this.getTaskCount() > 0) {
        Row({ space: 8 }) {
          Text('任务').fontSize(12).fontColor('#666')
          Button('<').onClick(() => this.prevTask())
          Text(this.getSelectedTaskTitle()).fontSize(14)
          Button('>').onClick(() => this.nextTask())
        }
        .justifyContent(FlexAlign.Center)
      }

      Row() {
        Column() {
          Canvas(this.ctx).width(this.ringSize).height(this.ringSize).onReady(() => this.drawRing())
          Text(`${pad2(this.minutes)}:${pad2(this.seconds)}`)
            .fontSize(44).fontWeight(FontWeight.Bold).padding({ top: 8 })
        }
      }
      .justifyContent(FlexAlign.Center)

      Row({ space: 12 }) {
        if (!this.running) {
          Button('开始').onClick(() => this.start())
            .backgroundColor('#2b6cff').fontColor('#fff')
            .padding({ left: 20, right: 20, top: 10, bottom: 10 }).borderRadius(12)
        } else {
          Button('暂停').onClick(() => this.pause())
            .backgroundColor('#ffcc00').fontColor('#333')
            .padding({ left: 20, right: 20, top: 10, bottom: 10 }).borderRadius(12)
        }
        Button('结束').onClick(() => this.finish())
          .backgroundColor('#eeeeee').fontColor('#333')
          .padding({ left: 16, right: 16, top: 10, bottom: 10 }).borderRadius(12)
        Button('重置').onClick(() => this.stop())
          .backgroundColor('#eeeeee').fontColor('#333')
          .padding({ left: 16, right: 16, top: 10, bottom: 10 }).borderRadius(12)
      }
      .justifyContent(FlexAlign.Center)

      Row({ space: 6 }) {
        Text('演示倍速').fontSize(12).fontColor('#666')
        Button(this.speed === 1 ? 'x1' : 'x30')
          .onClick(() => { this.speed = this.speed === 1 ? 30 : 1 })
          .backgroundColor('#f0f7ff').fontColor('#2b6cff')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 }).borderRadius(10)
      }
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 8 })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({ top: 16, bottom: 16 })
  }
}
