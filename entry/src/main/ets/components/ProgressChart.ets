/**
 * 进展折线图组件（Canvas绘制）
 * 展示动作的重量/1RM趋势
 */

@Component
export struct ProgressChart {
  /** 图表数据：日期 → 数值 */
  private dataPoints: { date: string; value: number }[] = [];
  /** 图表标题 */
  private title: string = '';
  /** 数值单位 */
  private unit: string = 'kg';
  /** 线条颜色 */
  private lineColor: ResourceColor = $r('app.color.primary');

  build() {
    Column() {
      // 标题
      if (this.title) {
        Text(this.title)
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ bottom: 8 })
      }

      if (this.dataPoints.length === 0) {
        Text('暂无数据')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .height(200)
      } else if (this.dataPoints.length === 1) {
        // 只有1个数据点，显示数值
        Text(`${this.dataPoints[0].value} ${this.unit}`)
          .fontSize(32)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Center)
          .height(200)
      } else {
        // Canvas折线图
        Canvas(this.canvasContext)
          .width('100%')
          .height(220)
          .onReady(() => {
            this.drawChart();
          })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
  }

  private canvasSettings: CanvasRenderingContext2DSettings = { antialias: true };
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);

  drawChart(): void {
    const ctx = this.canvasContext;
    const width = ctx.width || 360;
    const height = ctx.height || 220;

    // 清空
    ctx.clearRect(0, 0, width, height);

    const padding = { top: 20, right: 20, bottom: 40, left: 50 };
    const chartW = width - padding.left - padding.right;
    const chartH = height - padding.top - padding.bottom;

    const points = this.dataPoints;
    const values = points.map(p => p.value);
    const minVal = Math.min(...values) * 0.9;
    const maxVal = Math.max(...values) * 1.1;
    const range = maxVal - minVal || 1;

    // 绘制Y轴网格线
    ctx.strokeStyle = 'rgba(255,255,255,0.06)';
    ctx.lineWidth = 0.5;
    const gridLines = 4;
    for (let i = 0; i <= gridLines; i++) {
      const y = padding.top + (chartH / gridLines) * i;
      ctx.beginPath();
      ctx.moveTo(padding.left, y);
      ctx.lineTo(width - padding.right, y);
      ctx.stroke();

      // Y轴标签
      const val = maxVal - (range / gridLines) * i;
      ctx.fillStyle = 'rgba(255,255,255,0.4)';
      ctx.font = '10px sans-serif';
      ctx.textAlign = 'right';
      ctx.fillText(`${Math.round(val)}`, padding.left - 6, y + 4);
    }

    // 计算数据点坐标
    const stepX = chartW / (points.length - 1);
    const coords = points.map((p, i) => ({
      x: padding.left + i * stepX,
      y: padding.top + chartH - ((p.value - minVal) / range) * chartH,
      date: p.date,
      value: p.value
    }));

    // 绘制折线
    ctx.strokeStyle = 'rgba(108,99,255,0.8)';
    ctx.lineWidth = 2;
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(coords[0].x, coords[0].y);
    for (let i = 1; i < coords.length; i++) {
      ctx.lineTo(coords[i].x, coords[i].y);
    }
    ctx.stroke();

    // 绘制数据点
    for (const c of coords) {
      ctx.beginPath();
      ctx.arc(c.x, c.y, 3, 0, Math.PI * 2);
      ctx.fillStyle = '#6C63FF';
      ctx.fill();
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 1;
      ctx.stroke();
    }

    // X轴日期标签（仅首尾及中间几个）
    const labelCount = Math.min(points.length, 5);
    const labelStep = Math.max(1, Math.floor(points.length / labelCount));

    for (let i = 0; i < coords.length; i += labelStep) {
      const c = coords[i];
      const dateParts = c.date.split('-');
      const shortDate = `${dateParts[1]}/${dateParts[2]}`;
      ctx.fillStyle = 'rgba(255,255,255,0.4)';
      ctx.font = '10px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(shortDate, c.x, height - padding.bottom + 16);
    }

    // 最大值标记
    const maxPoint = coords.reduce((max, c) => c.value > max.value ? c : max, coords[0]);
    ctx.fillStyle = '#FF9800';
    ctx.font = '11px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(`MAX ${maxPoint.value}${this.unit}`, maxPoint.x, maxPoint.y - 10);
  }
}
