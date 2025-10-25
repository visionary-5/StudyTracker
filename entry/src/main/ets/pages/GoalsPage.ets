import { store } from '../data/Store'
import { Goal } from '../data/types'

@Component
export struct GoalsPage {
  @State title: string = ''
  @State target: string = '1200'

  // 用状态保存派生数据，避免在 build 里写计算语句
  @State private total: number = 1200
  @State private done: number = 0
  @State private rate: number = 0

  aboutToAppear() {
    this.computeProgress()
  }

  private computeProgress() {
    const g = store.goals.find(x => x.id === 'semester-1')
    const total = g?.targetMinutes ?? (Number(this.target) || 1200)
    const done = g?.achievedMinutes ?? store.sessions
      .filter(s => s.type === 'focus')
      .reduce((a, b) => a + b.durationMin, 0)
    const rate = total > 0 ? Math.min(100, Math.round(done / total * 100)) : 0

    this.total = total
    this.done = done
    this.rate = rate
  }

  save() {
    const achieved = store.sessions
      .filter(s => s.type === 'focus')
      .reduce((a, b) => a + b.durationMin, 0)

    const g: Goal = {
      id: 'semester-1',
      title: this.title || '本学期学习目标',
      targetMinutes: Number(this.target) || 1200,
      achievedMinutes: achieved,
      startAt: Date.now(),
      endAt: Date.now() + 90 * 24 * 3600 * 1000
    }
    store.setOrUpdateGoal(g)
    this.computeProgress() // 保存后刷新进度
  }

  build() {
    Column({ space: 12 }) {
      Text('学期目标')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .padding({ top: 12, bottom: 12 })

      TextInput({ placeholder: '目标标题（可选）' })
        .onChange((v: string) => { this.title = v })
        .padding({ top: 8, bottom: 8 })

      // 注：若 SDK 不支持 InputType，这一行可去掉
      TextInput({ placeholder: '目标分钟数' })
        .type(InputType.Number)
        .onChange((v: string) => {
          this.target = v
          this.computeProgress()
        })
        .padding({ top: 8, bottom: 8 })

      Button('保存/更新')
        .onClick(() => this.save())
        .padding({ top: 8, bottom: 8 })

      Text(`进度：${this.done}/${this.total} 分钟（${this.rate}%）`).padding({ top: 8, bottom: 8 })

      Row() {
        Blank().backgroundColor('#2b6cff').width(`${this.rate}%`).height(16).borderRadius(8)
        Blank().backgroundColor('#e5e5e5').width(`${100 - this.rate}%`).height(16).borderRadius(8)
      }
      .width('100%')
      .padding({ top: 4, bottom: 12 })
    }
    .width('100%')
  }
}

