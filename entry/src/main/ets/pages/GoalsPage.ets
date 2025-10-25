import { store } from '../data/Store'
import { Goal, Session } from '../data/types'

function pad2(n: number): string { return n < 10 ? ('0' + n) : '' + n }
function formatDateInline(v: string): string {
  const d = v.replace(/[^0-9]/g, '').slice(0, 8)
  const y = d.slice(0, 4), m = d.slice(4, 6), day = d.slice(6, 8)
  let out = y; if (m.length) out += '-' + m; if (day.length) out += '-' + day
  return out
}
function parseDate(dStr: string): number | undefined {
  if (!dStr || dStr.length < 8) return undefined
  const p = dStr.split('-'); const y = Number(p[0] || 0), m = Number(p[1] || 1), d = Number(p[2] || 1)
  const ts = new Date(y, (m || 1) - 1, d || 1, 0, 0, 0, 0).getTime()
  return isNaN(ts) ? undefined : ts
}
function minutesInRange(sessions: Session[], s: number, e: number): number {
  return sessions
    .filter(x => x.type === 'focus' && x.startAt >= s && x.startAt < e)
    .reduce((a, b) => a + b.durationMin, 0)
}

interface GoalView {
  id: string
  title: string
  startAt: number
  endAt: number
  targetMinutes: number
  done: number
  rate: number
  daysLeft: number
  dailyNeed: number
}

@Component
export struct GoalsPage {
  @State title: string = ''
  @State start: string = ''
  @State end: string = ''
  @State target: string = '1200'

  @State private currentGoalId: string = ''
  @State private views: GoalView[] = []
  @State private selectedIndex: number = -1

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ringCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private ringSize: number = 200

  aboutToAppear(): void { this.refresh() }

  private buildViews(): GoalView[] {
    const arr: GoalView[] = []
    for (let i = 0; i < store.goals.length; i++) {
      const g = store.goals[i]
      const done = minutesInRange(store.sessions, g.startAt, g.endAt)
      const total = g.targetMinutes
      const rate = total > 0 ? Math.min(100, Math.round(done / total * 100)) : 0
      const now = Date.now()
      const daysLeft = now <= g.endAt ? Math.max(0, Math.ceil((g.endAt - now) / (24*3600*1000))) : 0
      const remaining = Math.max(0, total - done)
      const dailyNeed = daysLeft > 0 ? Math.ceil(remaining / daysLeft) : remaining
      arr.push({ id: g.id, title: g.title, startAt: g.startAt, endAt: g.endAt, targetMinutes: total, done, rate, daysLeft, dailyNeed })
    }
    return arr
  }

  private refresh(): void {
    this.views = this.buildViews()
    if (this.views.length > 0) {
      const idx = this.currentGoalId ? this.views.findIndex(v => v.id === this.currentGoalId) : 0
      this.selectedIndex = idx >= 0 ? idx : 0
      this.currentGoalId = this.views[this.selectedIndex].id
    } else { this.selectedIndex = -1; this.currentGoalId = '' }
    this.drawRing() // 刷新时重画
  }

  private save(): void {
    const t = (this.title || '学习目标').trim()
    const sTs = parseDate(this.start)
    const eTs = parseDate(this.end)
    const tgtNum = Number(this.target)
    if (!sTs || !eTs || isNaN(tgtNum) || tgtNum <= 0) return

    const g: Goal = { id: Date.now().toString(), title: t, targetMinutes: tgtNum, achievedMinutes: 0, startAt: sTs, endAt: eTs }
    store.setOrUpdateGoal(g)
    this.title = ''; this.start = ''; this.end = ''; this.target = '1200'
    this.refresh()
  }

  private drawRing(): void {
    if (this.selectedIndex < 0 || this.selectedIndex >= this.views.length) {
      this.ringCtx.clearRect(0, 0, this.ringSize, this.ringSize); return
    }
    const v = this.views[this.selectedIndex]
    const ctx = this.ringCtx
    const size = this.ringSize
    const cx = size/2, cy = size/2, r = (size - 14)/2
    ctx.clearRect(0, 0, size, size)
    ctx.beginPath(); ctx.strokeStyle = '#e6eaf2'; ctx.lineWidth = 12; ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke()
    ctx.beginPath(); ctx.strokeStyle = '#2b6cff'; ctx.lineWidth = 12
    const startAng = -Math.PI/2; const endAng = startAng + (v.rate/100) * Math.PI*2
    ctx.arc(cx, cy, r, startAng, endAng); ctx.stroke()
  }

  private hasGoal(): boolean { return this.views.length > 0 }
  private currentTitle(): string { return this.hasGoal() ? this.views[this.selectedIndex].title : '暂无目标' }
  private currentDoneText(): string {
    if (!this.hasGoal()) return ''
    const v = this.views[this.selectedIndex]
    return `已完成 ${v.done}/${v.targetMinutes} 分钟`
  }
  private currentRemainText(): string {
    if (!this.hasGoal()) return ''
    const v = this.views[this.selectedIndex]
    const rem = Math.max(0, v.targetMinutes - v.done)
    return `剩余 ${rem} 分钟`
  }
  private currentPlanText(): string {
    if (!this.hasGoal()) return ''
    const v = this.views[this.selectedIndex]
    return v.daysLeft > 0 ? `剩余 ${v.daysLeft} 天 · 建议日均 ${v.dailyNeed} 分钟` : '已到期或未设置剩余天数'
  }
  private currentRangeText(): string {
    if (!this.hasGoal()) return ''
    const v = this.views[this.selectedIndex]
    const ds = new Date(v.startAt), de = new Date(v.endAt)
    return `起止：${ds.getFullYear()}-${pad2(ds.getMonth()+1)}-${pad2(ds.getDate())} 至 ${de.getFullYear()}-${pad2(de.getMonth()+1)}-${pad2(de.getDate())}`
  }
  private currentRateText(): string { return this.hasGoal() ? `${this.views[this.selectedIndex].rate}%` : '0%' }

  private prevGoal(): void {
    if (!this.hasGoal()) return
    this.selectedIndex = (this.selectedIndex - 1 + this.views.length) % this.views.length
    this.currentGoalId = this.views[this.selectedIndex].id
    this.drawRing()
  }
  private nextGoal(): void {
    if (!this.hasGoal()) return
    this.selectedIndex = (this.selectedIndex + 1) % this.views.length
    this.currentGoalId = this.views[this.selectedIndex].id
    this.drawRing()
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text('目标').fontSize(12).fontColor('#666')
        if (this.hasGoal()) {
          Button('<').onClick(() => this.prevGoal())
          Text(this.currentTitle()).fontSize(16).fontWeight(FontWeight.Medium)
          Button('>').onClick(() => this.nextGoal())
        } else {
          Text('暂无目标').fontSize(14).fontColor('#999')
        }
      }
      .padding({ top: 8, left: 16, right: 16 })

      if (this.hasGoal()) {
        Row() {
          Column() {
            Canvas(this.ringCtx).width(this.ringSize).height(this.ringSize).onReady(() => this.drawRing())
            Text(this.currentRateText()).fontSize(24).fontWeight(FontWeight.Bold).padding({ top: 8 })
          }
          .padding({ right: 12 })

          Column({ space: 6 }) {
            Text(this.currentDoneText()).fontSize(14)
            Text(this.currentRemainText()).fontSize(12).fontColor('#666')
            Text(this.currentPlanText()).fontSize(12).fontColor('#666')
            Text(this.currentRangeText()).fontSize(12).fontColor('#999').padding({ top: 4 })
          }
          .layoutWeight(1)
        }
        .padding({ left: 16, right: 16 })
      }

      Column({ space: 8 }) {
        Text('新建目标').fontSize(14).fontWeight(FontWeight.Medium).padding({ top: 8 })
        TextInput({ placeholder: '标题（如：本学期学习）' })
          .onChange((v: string) => this.title = v).width('100%').height(38)
          .backgroundColor('#f3f4f6').borderRadius(12).padding({ left: 12, right: 12 })
        Row({ space: 8 }) {
          TextInput({ placeholder: '开始 YYYY-MM-DD' })
            .onChange((v: string) => this.start = formatDateInline(v))
            .layoutWeight(1).height(38).backgroundColor('#f3f4f6').borderRadius(12).padding({ left: 12, right: 12 })
          TextInput({ placeholder: '结束 YYYY-MM-DD' })
            .onChange((v: string) => this.end = formatDateInline(v))
            .layoutWeight(1).height(38).backgroundColor('#f3f4f6').borderRadius(12).padding({ left: 12, right: 12 })
        }
        TextInput({ placeholder: '目标分钟数（如 1200）' })
          .type(InputType.Number) // 若不支持，删掉该行
          .onChange((v: string) => this.target = v)
          .width(160).height(38).backgroundColor('#f3f4f6').borderRadius(12).padding({ left: 12, right: 12 })
        Button('保存目标').onClick(() => this.save())
          .backgroundColor('#2b6cff').fontColor('#fff')
          .padding({ left: 16, right: 16, top: 10, bottom: 10 }).borderRadius(12)
      }
      .padding({ left: 16, right: 16, bottom: 12 })
    }
    .width('100%')
  }
}
