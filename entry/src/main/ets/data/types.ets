export interface Task {
  id: string
  title: string
  minutesPlanned?: number
  minutesDone: number
  done: boolean
  createdAt: number
  dueAt?: number
  completedAt?: number
  tags?: string[]
  note?: string // 备注
}

// 精准定义允许被更新的字段
export interface TaskPatch {
  title?: string
  minutesPlanned?: number
  minutesDone?: number
  done?: boolean
  createdAt?: number
  dueAt?: number
  completedAt?: number
  tags?: string[]
  note?: string
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

