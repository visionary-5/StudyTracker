// entry/src/main/ets/data/Store.ets
import { Task, Session, Goal } from './types'

export class Store {
  tasks: Task[] = []
  sessions: Session[] = []
  goals: Goal[] = []

  private static inst: Store | null = null
  static get I(): Store {
    if (!Store.inst) Store.inst = new Store()
    return Store.inst!
  }

  // ---- Task APIs ----
  addTask(title: string, minutesPlanned?: number): Task {
    const t: Task = {
      id: (Date.now() + Math.random()).toString(),
      title, minutesPlanned, minutesDone: 0, done: false,
      createdAt: Date.now()
    }
    this.tasks.unshift(t)
    this.persist()
    return t
  }
  toggleTask(id: string, done: boolean) {
    const t = this.tasks.find(x => x.id === id)
    if (t) { t.done = done; this.persist() }
  }
  removeTask(id: string) {
    this.tasks = this.tasks.filter(x => x.id !== id)
    this.persist()
  }
  addMinutesToTask(id: string, min: number) {
    const t = this.tasks.find(x => x.id === id)
    if (t) { t.minutesDone += min; this.persist() }
  }

  // ---- Sessions ----
  addSession(s: Session) {
    this.sessions.push(s)
    if (s.taskId) this.addMinutesToTask(s.taskId, s.durationMin)
    this.persist()
  }

  // ---- Goals ----
  setOrUpdateGoal(g: Goal) {
    const idx = this.goals.findIndex(x => x.id === g.id)
    if (idx >= 0) this.goals[idx] = g; else this.goals.push(g)
    this.persist()
  }

  // ---- Stats helpers ----
  minutesByDay(startTs: number, endTs: number): number {
    return this.sessions
      .filter(s => s.type === 'focus' && s.startAt >= startTs && s.startAt < endTs)
      .reduce((sum, s) => sum + s.durationMin, 0)
  }

  // ---- Persistence 占位（后续换 Preferences）----
  persist() {
    // TODO: 接入 @ohos.data.preferences 实现读写
  }
}

export const store = Store.I
