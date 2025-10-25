import { store } from '../data/Store'

function startOfDay(ts: number): number { const d = new Date(ts); d.setHours(0,0,0,0); return d.getTime() }
function addDays(ts: number, d: number): number { return ts + d * 24 * 3600 * 1000 }

type RangeKey = 'today' | '7d' | '30d'
interface ChartData { labels: string[]; values: number[]; max: number }

@Component
export struct StatsPage {
  @State private range: RangeKey = '7d'
  @State private chartData: ChartData = { labels: [], values: [], max: 60 }
  @State private totalMin: number = 0
  @State private streak: number = 0
  @State private devOpen: boolean = false

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  aboutToAppear(): void { this.refresh() }

  private getDays(): number {
    if (this.range === 'today') return 1
    if (this.range === '30d') return 30
    return 7
  }

  private computeStreak(days: number): number {
    const today0 = startOfDay(Date.now())
    let cnt = 0
    for (let i = 0; i < days; i++) {
      const s = addDays(today0, -i)
      const e = addDays(s, 1)
      const m = store.minutesByDay(s, e)
      if (m > 0) cnt++
      else break
    }
    return cnt
  }

  private getChartData(): ChartData {
    const days = this.getDays()
    const today0 = startOfDay(Date.now())
    const labels: string[] = []
    const values: number[] = []
    let sum = 0
    for (let i = days - 1; i >= 0; i--) {
      const s = addDays(today0, -i)
      const e = addDays(s, 1)
      const d = new Date(s)
      labels.push(`${d.getMonth() + 1}/${d.getDate()}`)
      const m = store.minutesByDay(s, e)
      values.push(m); sum += m
    }
    const max = Math.max(60, ...values)
    this.totalMin = sum
    this.streak = this.computeStreak(Math.min(30, days))
    return { labels, values, max }
  }

  private drawChart(): void {
    const days = this.getDays()
    const w = days * 44
    const h = 180
    const baseY = 150
    const barW = 24
    const gap = 44
    const ctx = this.ctx

    ctx.fillStyle = '#ffffff'; ctx.fillRect(0, 0, w, h)
    ctx.strokeStyle = '#f0f0f0'; ctx.lineWidth = 1
    for (let i = 0; i < 4; i++) {
      const y = baseY - (i + 1) * 30
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke()
    }

    for (let i = 0; i < this.chartData.values.length; i++) {
      const v = this.chartData.values[i]
      const barH = Math.round(v / this.chartData.max * 120)
      const x = i * gap + 10
      const y = baseY - barH
      ctx.fillStyle = '#2b6cff'; ctx.fillRect(x, y, barW, barH)
      if (v > 0) { ctx.fillStyle = '#333'; ctx.font = '12px sans-serif'; ctx.fillText(v.toString(), x, y - 4) }
    }
  }

  private refresh(): void {
    this.chartData = this.getChartData()
    this.drawChart()
  }

  private seedToday25(): void {
    store.addSession({ id: Date.now().toString(), startAt: Date.now() - 25 * 60 * 1000, durationMin: 25, type: 'focus' })
    this.refresh()
  }
  private seedRandomWeek(): void {
    const today0 = startOfDay(Date.now())
    for (let i = 0; i < 7; i++) {
      const s = addDays(today0, -i) + 9 * 3600 * 1000
      const m = Math.floor(Math.random() * 90)
      if (m > 0) store.addSession({ id: (Date.now() + i).toString(), startAt: s, durationMin: m, type: 'focus' })
    }
    this.refresh()
  }
  private clearData(): void { store.sessions = []; this.refresh() }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Button('今日').onClick(() => { this.range = 'today'; this.refresh() })
          .backgroundColor(this.range === 'today' ? '#2b6cff' : '#eaeaea')
          .fontColor(this.range === 'today' ? '#fff' : '#333')
        Button('7天').onClick(() => { this.range = '7d'; this.refresh() })
          .backgroundColor(this.range === '7d' ? '#2b6cff' : '#eaeaea')
          .fontColor(this.range === '7d' ? '#fff' : '#333')
        Button('30天').onClick(() => { this.range = '30d'; this.refresh() })
          .backgroundColor(this.range === '30d' ? '#2b6cff' : '#eaeaea')
          .fontColor(this.range === '30d' ? '#fff' : '#333')

        Blank().layoutWeight(1)

        Button(this.devOpen ? '隐藏调试' : '调试')
          .onClick(() => this.devOpen = !this.devOpen)
          .backgroundColor('#f0f7ff').fontColor('#2b6cff')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 }).borderRadius(10)
      }
      .padding({ top: 8, left: 16, right: 16 })

      Row({ space: 16 }) {
        Text(`总计 ${this.totalMin} 分钟`).fontSize(14).fontWeight(FontWeight.Medium)
        Text(`连续 ${this.streak} 天`).fontSize(14).fontColor('#666')
      }
      .padding({ left: 16, right: 16 })

      Row() {
        Canvas(this.ctx).width(this.getDays() * 44).height(180).onReady(() => this.drawChart())
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Row({ space: 20 }) {
        ForEach(this.chartData.labels, (lb: string) => Text(lb).fontSize(12), (lb: string) => lb)
      }
      .padding({ top: 4, bottom: 4 })
      .justifyContent(FlexAlign.Center)

      if (this.totalMin === 0) {
        Row() {
          Text('暂无专注数据，开始一次专注试试吧').fontSize(12).fontColor('#999')
        }
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8 })
      }

      if (this.devOpen) {
        Row({ space: 8 }) {
          Button('今天 +25min').onClick(() => this.seedToday25())
          Button('随机一周').onClick(() => this.seedRandomWeek())
          Button('清空').onClick(() => this.clearData())
        }
        .padding({ left: 16, right: 16, bottom: 8 })
      }
    }
    .width('100%')
  }
}
