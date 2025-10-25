import { store } from '../data/Store'
import { Task } from '../data/types'
import router from '@ohos.router'

type FilterKey = 'active' | 'done' | 'all'
interface TaskFilter { key: FilterKey; text: string }
const FILTERS: TaskFilter[] = [
  { key: 'active', text: '未完成' },
  { key: 'done', text: '已完成' },
  { key: 'all', text: '全部' }
]

// 工具函数
function pad2(n: number): string { return n < 10 ? ('0' + n) : '' + n }
function weekdayCN(d: Date): string {
  const arr: string[] = ['日','一','二','三','四','五','六']
  return '周' + arr[d.getDay()]
}
function fmtDateTime(ts: number): string {
  const d: Date = new Date(ts)
  return `${pad2(d.getMonth() + 1)}/${pad2(d.getDate())} ${pad2(d.getHours())}:${pad2(d.getMinutes())}`
}
function parseDueAt(dStr: string, tStr: string): number | undefined {
  // 期望 YYYY-MM-DD 和 HH:mm（可留空）
  if (!dStr || dStr.length < 8) return undefined
  const dParts: string[] = dStr.split('-')
  const y: number = Number(dParts.length > 0 ? dParts[0] : '0')
  const m: number = Number(dParts.length > 1 ? dParts[1] : '1')
  const d: number = Number(dParts.length > 2 ? dParts[2] : '1')
  let hh: number = 0
  let mm: number = 0
  if (tStr && tStr.length >= 4) {
    const tParts: string[] = tStr.split(':')
    hh = Number(tParts.length > 0 ? tParts[0] : '0')
    mm = Number(tParts.length > 1 ? tParts[1] : '0')
  }
  const dt: Date = new Date(y, (m || 1) - 1, d || 1, hh || 0, mm || 0, 0, 0)
  const ts: number = dt.getTime()
  return isNaN(ts) ? undefined : ts
}

@Component
export struct TasksPage {
  // 输入
  @State title: string = ''
  @State dueDate: string = ''   // YYYY-MM-DD
  @State dueTime: string = ''   // HH:mm
  @State planned: string = ''   // 预估分钟（可空）
  @State private lastPlanned: string = '' // 记住上一条

  // 视图
  @State private filter: FilterKey = 'active'
  @State private list: Task[] = []

  // 顶部时钟
  @State private nowStr: string = ''
  private clockId: number = 0

  private readonly filters: TaskFilter[] = FILTERS

  aboutToAppear() {
    this.refresh()
    this.tickClock()
    this.clockId = setInterval(() => this.tickClock(), 1000)
  }
  aboutToDisappear() {
    if (this.clockId) { clearInterval(this.clockId); this.clockId = 0 }
  }

  private tickClock(): void {
    const now: Date = new Date()
    this.nowStr = `${now.getFullYear()}-${pad2(now.getMonth()+1)}-${pad2(now.getDate())} ${pad2(now.getHours())}:${pad2(now.getMinutes())}:${pad2(now.getSeconds())} ${weekdayCN(now)}`
  }

  private isOverdue(t: Task): boolean {
    return !t.done && t.dueAt !== undefined && t.dueAt < Date.now()
  }
  private cardBg(t: Task): string {
    return this.isOverdue(t) ? '#fff4f4' : '#f7f7f7'
  }
  private dueLine(t: Task): string {
    if (t.dueAt === undefined) return '无截止'
    const left: number = t.dueAt - Date.now()
    const abs: number = left >= 0 ? left : -left
    const day: number = Math.floor(abs / (24*3600*1000))
    const hour: number = Math.floor((abs % (24*3600*1000)) / (3600*1000))
    const tail: string = (day > 0 ? `${day}天` : '') + (hour > 0 ? `${hour}小时` : (day > 0 ? '' : '不到1小时'))
    const head: string = left >= 0 ? '剩余' : '已逾期'
    return `截止 ${fmtDateTime(t.dueAt)} · ${head}${tail}`
  }

  private refresh(): void {
    let arr: Task[] = store.tasks.slice()
    if (this.filter === 'active') {
      arr = arr.filter((t: Task) => !t.done)
      // 过期优先，再按截止时间升序，无截止排最后
      arr.sort((a: Task, b: Task) => {
        const ao: number = this.isOverdue(a) ? 0 : 1
        const bo: number = this.isOverdue(b) ? 0 : 1
        if (ao !== bo) return ao - bo
        const ad: number = (a.dueAt !== undefined) ? a.dueAt : 9_000_000_000_000 // 避免 Number.MAX_SAFE_INTEGER
        const bd: number = (b.dueAt !== undefined) ? b.dueAt : 9_000_000_000_000
        return ad - bd
      })
    } else if (this.filter === 'done') {
      arr = arr.filter((t: Task) => t.done)
      arr.sort((a: Task, b: Task) => {
        const ac: number = (a.completedAt !== undefined) ? a.completedAt : 0
        const bc: number = (b.completedAt !== undefined) ? b.completedAt : 0
        return bc - ac
      })
    } else {
      const active: Task[] = arr.filter((t: Task) => !t.done)
      active.sort((a: Task, b: Task) => {
        const ad: number = (a.dueAt !== undefined) ? a.dueAt : 9_000_000_000_000
        const bd: number = (b.dueAt !== undefined) ? b.dueAt : 9_000_000_000_000
        return ad - bd
      })
      const done: Task[] = arr.filter((t: Task) => t.done)
      done.sort((a: Task, b: Task) => {
        const ac: number = (a.completedAt !== undefined) ? a.completedAt : 0
        const bc: number = (b.completedAt !== undefined) ? b.completedAt : 0
        return bc - ac
      })
      arr = active.concat(done)
    }
    this.list = arr
  }

  private addTask(): void {
    const titleTrim: string = this.title.trim()
    if (!titleTrim) return

    // 预估分钟沿用上一条（可留空）
    let plannedStr: string = this.planned.trim()
    if (!plannedStr && this.lastPlanned) plannedStr = this.lastPlanned
    const plannedNum: number = plannedStr ? Number(plannedStr) : NaN
    const plannedFinal: number | undefined =
      (!isNaN(plannedNum) && plannedNum > 0) ? plannedNum : undefined
    if (plannedFinal !== undefined) this.lastPlanned = String(plannedFinal)

    const dueAt: number | undefined = parseDueAt(this.dueDate, this.dueTime)

    store.addTask(titleTrim, plannedFinal, dueAt) // store 已支持第3参
    // 清标题；预估/截止可保留，便于连续添加相似任务
    this.title = ''
    this.refresh()
  }

  private completeTask(id: string): void {
    store.toggleTask(id, true)
    this.refresh()
  }
  private restoreTask(id: string): void {
    store.toggleTask(id, false)
    this.refresh()
  }
  private deleteTask(id: string): void {
    store.removeTask(id)
    this.refresh()
  }

  build() {
    Column({ space: 12 }) {
      // 顶部时钟
      Row() {
        Text(this.nowStr).fontSize(12).fontColor('#666')
      }
      .padding({ top: 8, left: 16, right: 16 })

      // 筛选
      Row({ space: 8 }) {
        ForEach(this.filters, (it: TaskFilter) => {
          Button(it.text)
            .onClick(() => { this.filter = it.key; this.refresh() })
            .backgroundColor(this.filter === it.key ? '#2b6cff' : '#eaeaea')
            .fontColor(this.filter === it.key ? '#ffffff' : '#333333')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
        }, (it: TaskFilter) => it.key)
      }
      .padding({ left: 16, right: 16 })

      // 输入区域
      Column({ space: 8 }) {
        TextInput({ placeholder: '新任务标题（如：提交周报）' })
          .onChange((v: string) => this.title = v)
          .width('100%').height(38)
          .backgroundColor('#f3f4f6').borderRadius(12)
          .padding({ left: 12, right: 12 })

        Row({ space: 8 }) {
          TextInput({ placeholder: '截止日期 YYYY-MM-DD' })
            .onChange((v: string) => this.dueDate = v)
            .width('60%').height(38)
            .backgroundColor('#f3f4f6').borderRadius(12)
            .padding({ left: 12, right: 12 })

          TextInput({ placeholder: 'HH:mm（可选）' })
            .onChange((v: string) => this.dueTime = v)
            .width('35%').height(38)
            .backgroundColor('#f3f4f6').borderRadius(12)
            .padding({ left: 12, right: 12 })
        }

        Row({ space: 8 }) {
          TextInput({ placeholder: '预估(分，可空)' })
          // 若 SDK 不支持 .type()，删掉下一行
            .type(InputType.Number)
            .onChange((v: string) => this.planned = v)
            .width(100).height(38)
            .backgroundColor('#f3f4f6').borderRadius(12)
            .padding({ left: 12, right: 12 })

          Button('添加')
            .onClick(() => this.addTask())
            .backgroundColor(this.title.trim().length > 0 ? '#2b6cff' : '#c9c9c9')
            .fontColor('#ffffff').height(38)
            .padding({ left: 16, right: 16 })
            .borderRadius(12)

          Blank().layoutWeight(1)
        }
      }
      .padding({ left: 16, right: 16 })

      // 列表
      List({ space: 10 }) {
        ForEach(this.list, (t: Task) => {
          ListItem() {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Column() {
                  Text(t.title)
                    .fontSize(16).fontWeight(FontWeight.Medium)
                    .fontColor(t.done ? '#999' : '#111')

                  Text(this.dueLine(t))
                    .fontSize(12)
                    .fontColor(this.isOverdue(t) ? '#c62828' : (t.done ? '#aaa' : '#666'))

                  if (t.minutesPlanned && t.minutesPlanned > 0) {
                    Text(`预估 ${t.minutesPlanned} 分钟`)
                      .fontSize(12).fontColor('#999')
                  }
                }
                .layoutWeight(1)

                if (!t.done) {
                  Button('完成')
                    .onClick(() => this.completeTask(t.id))
                    .backgroundColor('#e8f2ff').fontColor('#2b6cff')
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .borderRadius(10)
                } else {
                  Button('恢复')
                    .onClick(() => this.restoreTask(t.id))
                    .backgroundColor('#f3f4f6').fontColor('#555')
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .borderRadius(10)
                }
                
                // 添加备注按钮
                Button('备注')
                  .onClick(() => {
                    // 跳转到备注编辑页面
                    router.push({
                      url: 'pages/NoteEditorPage',
                      params: {
                        taskId: t.id,
                        taskTitle: t.title
                      }
                    })
                  })
                  .backgroundColor('#f3f4f6').fontColor('#555')
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .borderRadius(10)
                
                Button('删除')
                  .onClick(() => this.deleteTask(t.id))
                  .backgroundColor('#ffecec').fontColor('#c62828')
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .borderRadius(10)
              }
            }
            .padding(12)
            .backgroundColor(this.cardBg(t))
            .borderRadius(12)
          }
        }, (t: Task) => t.id)
      }
      .width('100%').height('100%').layoutWeight(1)
      .padding({ left: 16, right: 16, bottom: 8 })
    }
    .width('100%')
  }
}
