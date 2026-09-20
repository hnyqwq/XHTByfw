@Component
export struct KeyboardLiftScroll {
  @Prop topAlign: boolean = false;
  scroller: Scroller = new Scroller();
  @BuilderParam content: () => void;

  build() {
    Scroll(this.scroller) {
      Column() {
        Column() {
          this.content()
        }
        .width('100%')
      }
      .constraintSize({ minHeight: '100%' })
      .width('100%')
      .justifyContent(this.topAlign ? FlexAlign.Start : FlexAlign.Center)
    }
    .scrollBar(BarState.Off)
    .clip(false)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .width('100%')
    .layoutWeight(1)
  }
}
