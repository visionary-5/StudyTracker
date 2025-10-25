import { store } from '../data/Store'

function startOfDay(ts: number): number {
  const d = new Date(ts); d.setHours(0, 0, 0, 0); return d.getTime()
}
function addDays(ts: number, d: number): number { return ts + d * 24 * 3600 * 1000 }

interface ChartData {
  labels: string[]
  values: number[]
  max: number
}

@Component
export struct StatsPage {
  private days: number = 7

  // 预创建 2D 上下文并传给 Canvas（onReady 是无参回调的版本）
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  @State private chartData: ChartData = { labels: [], values: [], max: 60 }

  aboutToAppear() {
    this.chartData = this.getChartData()
  }

  private getChartData(): ChartData {
    const today0 = startOfDay(Date.now())
    const labels: string[] = []
    const values: number[] = []
    for (let i = this.days - 1; i >= 0; i--) {
      const s = addDays(today0, -i)
      const e = addDays(s, 1)
      labels.push(`${new Date(s).getMonth() + 1}/${new Date(s).getDate()}`)
      values.push(store.minutesByDay(s, e))
    }
    const max = Math.max(60, ...values)
    return { labels, values, max }
  }

  private drawChart() {
    const w = this.days * 44
    const h = 160
    const baseY = 140
    const barW = 24
    const gap = 44
    const ctx = this.ctx

    // 背景
    ctx.fillStyle = '#f5f5f5'
    ctx.fillRect(0, 0, w, h)

    // 柱子 + 数值
    for (let i = 0; i < this.chartData.values.length; i++) {
      const v = this.chartData.values[i]
      const barH = Math.round(v / this.chartData.max * 120)
      const x = i * gap + 14
      const y = baseY - barH

      ctx.fillStyle = '#2b6cff'
      ctx.fillRect(x, y, barW, barH)

      ctx.fillStyle = '#333'
      ctx.font = '12px sans-serif'
      ctx.fillText(v.toString(), x, y - 4)
    }
  }

  build() {
    Column({ space: 12 }) {
      Text(`最近 ${this.days} 天学习时长（分钟）`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .padding({ top: 12, bottom: 12 })

      // 画布居中：花括号紧跟 Row()，修饰符放后面
      Row() {
        Canvas(this.ctx)
          .width(this.days * 44)
          .height(160)
          .onReady(() => this.drawChart())
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      // X 轴标签
      Row({ space: 20 }) {
        ForEach(this.chartData.labels, (lb: string) => Text(lb).fontSize(12), (lb: string) => lb)
      }
      .padding({ top: 8, bottom: 12 })
    }
    .width('100%')
  }
}
