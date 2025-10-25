import { Task, Session, Goal, TaskPatch } from './types'

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
  addTask(title: string, minutesPlanned?: number, dueAt?: number): Task {
    const t: Task = {
      id: (Date.now() + Math.random()).toString(),
      title,
      minutesPlanned,
      minutesDone: 0,
      done: false,
      createdAt: Date.now(),
      dueAt
    }
    this.tasks.unshift(t)
    this.persist()
    return t
  }

  // 受控更新（白名单字段）
  updateTask(id: string, patch: TaskPatch): void {
    const t = this.tasks.find(x => x.id === id)
    if (!t) return
    if (patch.title !== undefined) t.title = patch.title
    if (patch.minutesPlanned !== undefined) t.minutesPlanned = patch.minutesPlanned
    if (patch.minutesDone !== undefined) t.minutesDone = patch.minutesDone
    if (patch.done !== undefined) t.done = patch.done
    if (patch.createdAt !== undefined) t.createdAt = patch.createdAt
    if (patch.dueAt !== undefined) t.dueAt = patch.dueAt
    if (patch.completedAt !== undefined) t.completedAt = patch.completedAt
    if (patch.tags !== undefined) t.tags = patch.tags
    if (patch.note !== undefined) t.note = patch.note
    this.persist()
  }

  toggleTask(id: string, done: boolean): void {
    const t = this.tasks.find(x => x.id === id)
    if (t) {
      t.done = done
      t.completedAt = done ? Date.now() : undefined
      this.persist()
    }
  }

  removeTask(id: string): void {
    this.tasks = this.tasks.filter(x => x.id !== id)
    this.persist()
  }

  addMinutesToTask(id: string, min: number): void {
    const t = this.tasks.find(x => x.id === id)
    if (t) { t.minutesDone += min; this.persist() }
  }

  // ---- Sessions ----
  addSession(s: Session): void {
    this.sessions.push(s)
    if (s.taskId) this.addMinutesToTask(s.taskId, s.durationMin)
    this.persist()
  }

  // ---- Goals ----
  setOrUpdateGoal(g: Goal): void {
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

  // ---- Persistence 占位 ----
  persist(): void {
    // TODO: 接入 @ohos.data.preferences 实现读写
  }
}

export const store = Store.I

