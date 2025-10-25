import { store } from '../data/Store'
import { Task } from '../data/types'

@Component
export struct TasksPage {
  @State title: string = ''
  @State planned: string = ''

  build() {
    Column({ space: 8 }) {
      // 输入行
      Row({ space: 8 }) {
        TextInput({ placeholder: '新任务标题' })
          .onChange((v: string) => this.title = v)
          .width('60%')

        TextInput({ placeholder: '预估分钟' })
          .type(InputType.Number) // 若 SDK 不支持，可去掉这行
          .onChange((v: string) => this.planned = v)
          .width('25%')

        Button('添加').onClick(() => {
          const t = this.title.trim()
          if (t.length > 0) {
            const p = Number(this.planned) || undefined
            store.addTask(t, p)
            this.title = ''
            this.planned = ''
          }
        })
      }
      .padding({ top: 12, bottom: 12 })

      // 任务列表（用权重填充剩余空间）
      List({ space: 6 }) {
        ForEach(store.tasks, (t: Task) => {
          ListItem() {
            Row({ space: 10 }) {
              Checkbox()
                .select(t.done)
                .onChange((checked: boolean) => store.toggleTask(t.id, checked))

              Column() {
                Text(t.title).fontSize(16).fontWeight(FontWeight.Medium)
                Text(`完成 ${t.minutesDone} / 预估 ${t.minutesPlanned ?? 0} 分钟`)
                  .fontSize(12).fontColor('#666')
              }
              .width('70%')

              Button('删除').onClick(() => store.removeTask(t.id))
            }
            .padding(10)
            .backgroundColor('#f7f7f7')
            .borderRadius(12)
          }
        }, (t: Task) => t.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ top: 4, bottom: 12 })
    }
    .width('100%')
  }
}
