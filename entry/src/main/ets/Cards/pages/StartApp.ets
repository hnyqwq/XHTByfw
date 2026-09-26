let storageStartApp = new LocalStorage()

@Entry(storageStartApp)
@Component
export struct Control_C1 {
  // 卡片尺寸(2=2x2, 4=4x4), EntryFormAbility.onAddForm 透传
  @LocalStorageProp('dimension') dimension: number = 2

  ClickToHome = (): void => {
    postCardAction(this, {
      'action': 'router',
      'abilityName': 'EntryAbility',
      'params': {
        'targetPage': 'SecondPage'
      }
    });
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 深空紫渐变底
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 160,
          colors: [['#191046', 0], ['#31217A', 0.55], ['#5B3FB8', 1]]
        })

      // 星云装饰圆(右上/左下, 半透明渐出)
      Column()
        .width(this.dimension === 4 ? 190 : 104)
        .height(this.dimension === 4 ? 190 : 104)
        .borderRadius('50%')
        .linearGradient({
          angle: 135,
          colors: [['rgba(139,124,246,0.55)', 0], ['rgba(139,124,246,0)', 1]]
        })
        .position({ x: '62%', y: '-14%' })

      Column()
        .width(this.dimension === 4 ? 150 : 84)
        .height(this.dimension === 4 ? 150 : 84)
        .borderRadius('50%')
        .linearGradient({
          angle: 315,
          colors: [['rgba(79,107,245,0.5)', 0], ['rgba(79,107,245,0)', 1]]
        })
        .position({ x: '-10%', y: '68%' })

      // 星点
      Text('✦')
        .fontSize(this.dimension === 4 ? 16 : 11)
        .fontColor('rgba(255,255,255,0.95)')
        .position({ x: '80%', y: '18%' })
      Text('✧')
        .fontSize(this.dimension === 4 ? 12 : 8)
        .fontColor('rgba(255,255,255,0.7)')
        .position({ x: '16%', y: '20%' })
      Text('✦')
        .fontSize(this.dimension === 4 ? 10 : 7)
        .fontColor('rgba(255,255,255,0.55)')
        .position({ x: '10%', y: '62%' })
      Text('·')
        .fontSize(this.dimension === 4 ? 14 : 10)
        .fontColor('rgba(255,255,255,0.6)')
        .position({ x: '68%', y: '74%' })
      Text('✧')
        .fontSize(this.dimension === 4 ? 9 : 6)
        .fontColor('rgba(255,255,255,0.5)')
        .position({ x: '88%', y: '56%' })

      // 中央内容: 图标 + 名称 + 标语
      Column() {
        Image($r('app.media.app_icon'))
          .width(this.dimension === 4 ? 112 : 58)
          .height(this.dimension === 4 ? 112 : 58)
          .borderRadius(this.dimension === 4 ? 27 : 14)

        Text($r('app.string.appname'))
          .fontColor('#FFFFFF')
          .fontSize(this.dimension === 4 ? 26 : 16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: this.dimension === 4 ? 18 : 10 })

        Text($r('app.string.card_slogan'))
          .fontColor('rgba(255,255,255,0.78)')
          .fontSize(this.dimension === 4 ? 14 : 10)
          .margin({ top: this.dimension === 4 ? 6 : 3 })
          .opacity(this.dimension === 4 ? 1 : 0.9)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .onClick(this.ClickToHome)
  }
}
