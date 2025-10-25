import { store } from '../data/Store'
import router from '@ohos.router'

// 定义参数类型接口
interface PageParams {
  taskId?: string;
  taskTitle?: string;
}

@Entry
@Component
export struct NoteEditorPage {
  @State note: string = ''
  private taskId: string = ''
  private taskTitle: string = ''

  aboutToAppear() {
    // 获取传入的参数
    let params = router.getParams();
    if (params) {
      // 使用类型断言处理参数
      const typedParams = params as PageParams;
      if (typedParams.taskId) {
        this.taskId = typedParams.taskId;
        this.taskTitle = typedParams.taskTitle || '';

        // 初始化时加载任务备注内容
        const task = store.tasks.find(t => t.id === this.taskId)
        if (task && task.note) {
          this.note = task.note
        }
      }
    }
  }

  saveNote() {
    // 保存备注到任务
    if (this.taskId) {
      store.updateTask(this.taskId, { note: this.note })
    }
  }

  build() {
    Column() {
      // 页面头部
      Row() {
        Button('返回')
          .onClick(() => {
            this.saveNote()
            router.back()
          })
          .backgroundColor('#2b6cff')
          .fontColor('#ffffff')
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .borderRadius(8)

        Text('编辑备注')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位元素保持居中
        Blank().width(80)
      }
      .padding({
        left: 16,
        right: 16,
        top: 16,
        bottom: 16
      })

      // 显示任务标题
      Row() {
        Text(`任务: ${this.taskTitle}`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .layoutWeight(1)
      }
      .padding({ left: 16, right: 16, bottom: 16 })

      // 备注编辑区域
      TextArea({ text: this.note, placeholder: '在此输入任务的详细备注信息...' })
        .onChange((value: string) => {
          this.note = value
        })
        .width('100%')
        .height('60%')
        .padding({ left: 16, right: 16 })
        .backgroundColor('#f7f7f7')
        .borderRadius(12)

      Blank()

      // 底部操作按钮
      Row() {
        Button('保存并返回')
          .onClick(() => {
            this.saveNote()
            router.back()
          })
          .backgroundColor('#2b6cff')
          .fontColor('#ffffff')
          .padding({
            left: 24,
            right: 24,
            top: 12,
            bottom: 12
          })
          .borderRadius(12)
          .layoutWeight(1)
      }
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
  }
}