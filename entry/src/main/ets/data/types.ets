// entry/src/main/ets/data/types.ets
export interface Task {
  id: string
  title: string
  minutesPlanned?: number
  minutesDone: number
  done: boolean
  createdAt: number
  dueAt?: number
  tags?: string[]
}

export interface Session {
  id: string
  taskId?: string
  startAt: number
  durationMin: number
  type: 'focus' | 'break'
}

export interface Goal {
  id: string
  title: string
  targetMinutes: number
  achievedMinutes: number
  startAt: number
  endAt: number
}
