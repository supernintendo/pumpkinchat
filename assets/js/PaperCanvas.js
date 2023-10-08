/**
 * @namespace
 * @property {string}  drawingContent         - A serialized %Pumpkinchat.Drawing{} for loading drawing content.
 * @property {string}  drawingMode            - The current drawing mode, either 'select' or 'pen'.
 * @property {number}  drawResolution         - The minimum distance between points when drawing.
 * @property {number}  hitTolerance           - The distance from a point to consider a click event.
 * @property {number}  minimumPointsPerPath   - The minimum number of points required to create a path.
 * @property {object}  mouseCurrentPoint      - The current mouse point.
 * @property {object}  mouseLastPoint         - The previous mouse point.
 * @property {object}  mouseOriginPoint       - The initial mouse point.
 * @property {boolean} mousePressed           - Whether the mouse is currently pressed.
 * @property {object}  path                   - The current drawing path.
 * @property {string}  persistEventName       - The name of the Phoenix event to trigger when persisting the drawing.
 * @property {object}  project                - The current paper.js project.
 * @property {string}  selectionType          - The type of selection, either 'fill', 'segment', 'stroke' or null.
 * @property {boolean} shiftDown              - Whether the shift key is currently pressed.
 */
const PaperCanvas = {
  drawingContent: null,
  drawingMode: 'select',
  drawResolution: 1,
  hitTolerance: 5,
  minimumPointsPerPath: 3,
  mouseCurrentPoint: null,
  mouseLastPoint: null,
  mouseOriginPoint: null,
  mousePressed: false,
  path: null,
  persistEventName: 'persist_drawing',
  project: null,
  selectionType: null,
  shiftDown: false,
  /**
   * Called when the component is mounted. 
   */
  mounted() {
    this.drawResolution = this.el.dataset.drawResolution || this.drawResolution
    this.drawingContent = this.el.dataset.drawingContent
    this.drawingMode = this.el.dataset.drawingMode || this.drawingMode
    paper.setup(this.el)

    if (this.drawingContent) {
      paper.project.importJSON(this.drawingContent)
    }
    this.bindEvents()
  },
  /**
   * Called when the component is updated on the server. 
   */
  updated() {
    this.drawResolution = this.el.dataset.drawResolution || this.drawResolution
    this.drawingMode = this.el.dataset.drawingMode || this.drawingMode
  },
  /**
   * Binds event listeners to the canvas element, window and component.
   */
  bindEvents() {
    this.handleEvent('persist', _data => this.handlePersist())
    this.el.addEventListener('mousedown', e => this.handleMouseDown(e))
    this.el.addEventListener('mouseup', e => this.handleMouseUp(e))
    this.el.addEventListener('mousemove', e => this.handleMouseMove(e))
    window.addEventListener('keydown', e => this.handleKeyDown(e))
    window.addEventListener('keyup', e => this.handleKeyUp(e))
  },
  /**
   * Creates a new paper.js Path object.
   */
  createPath(params) {
    let segments = params.segments || []
    let path = {
      segments: segments.map(([x, y]) => this.createPoint(x, y)),
      fillColor: params.fillColor || '#F97316',
      strokeCap: 'round',
      strokeColor: params.strokeColor || '#B45309',
      strokeWidth: 2,
      fullySelected: params.fullySelected || false
    }
    return new paper.Path({ ...params, ...path })
  },
  /**
   * Creates a new paper.js Point object.
   */
  createPoint(x, y) {
    let elBounds = this.el.getBoundingClientRect()
    let pointX = x - elBounds.x
    let pointY = y - elBounds.y

    return new paper.Point(pointX, pointY)
  },
  /**
   * Deselects all selected items.
   */
  deselectAll() {
    paper.project.getSelectedItems().forEach(item => item.selected = false)
  },
  /**
   * Returns the delta between two points as a paper.js Point object.
   */
  getDelta(pointA, pointB) {
    let x = pointA.x - pointB.x
    let y = pointA.y - pointB.y

    return new paper.Point(x, y)
  },
  /**
   * Returns the distance between two points.
   */
  getDistance(pointA, pointB) {
    return pointA.getDistance(pointB)
  },
  /**
   * Handles a keydown event.
   */
  handleKeyDown(e) {
    this.shiftDown = e.shiftKey

    if (e.key === 'Delete' || e.key === 'Backspace') {
      this.handleSelectionDeleted()
    }
  },
  /**
   * Handles a keyup event.
   */
  handleKeyUp(e) {
    this.shiftDown = e.shiftKey
  },
  /**
   * Handles a mousedown event. This triggers once per click,
   * when the mouse is first pressed.
   */
  handleMouseDown(e) {
    let point = this.createPoint(e.clientX, e.clientY)
    let hitResult = paper.project.hitTest(point, {
      segments: true,
      stroke: true,
      fill: true,
      tolerance: this.hitTolerance
    })
    // Initialize all cached mouse points so that distance
    // calculations are accurate when the mouse is first pressed.
    this.mouseOriginPoint = point
    this.mouseCurrentPoint = point
    this.mouseLastPoint = point
    this.mousePressed = true

    if (this.drawingMode === 'select' && hitResult) {
      this.handleDrawingClicked(hitResult)
    } else if (this.drawingMode === 'select' && !hitResult) {
      this.handleCanvasClicked(e)
    } else if (this.drawingMode === 'pen') {
      this.handleDrawingStarted(e)
    }
  },
  /**
   * Creates a new path to be drawn to. This triggers once per click,
   * when the mouse is first pressed.
   */
  handleDrawingStarted(e) {
    if (this.path) {
      this.path.selected = false
    }
    this.path = this.createPath({
      segments: [[e.clientX, e.clientY]],
      fullySelected: true
    })
  },
  /**
   * Handles a click on a drawing. This triggers once per click,
   * when the mouse is first pressed.
   */
  handleDrawingClicked(hitResult) {
    // Holding the shift key down allows multiple items to be selected.
    if (!this.shiftDown) {
      this.deselectAll()
    }
    // Cache the selection type so that it can be checked when moving
    // and deleting selected items.
    this.selectionType = hitResult.type

    if (hitResult.type === 'fill') {
      hitResult.item.fullySelected = true
      hitResult.item.selected = true
    } else if (hitResult.type === 'segment') {
      hitResult.segment.selected = true
    } else if (hitResult.type === 'stroke') {
			let point = hitResult.item.insert(hitResult.location.index + 1, this.mouseLastPoint);

      point.selected = true
      this.selectionType = 'segment'
    }
  },
  /**
   * Handles a click on the canvas. This triggers once per click,
   * when the mouse is first pressed and deselects all items.
   */
  handleCanvasClicked(e) {
    this.deselectAll()
  },
  /**
   * Handles a mousemove event. This triggers continuously while
   * the mouse is pressed.
   */
  handleMouseMove(e) {
    if (this.mousePressed) {
      this.mouseLastPoint = this.mouseCurrentPoint
      this.mouseCurrentPoint = this.createPoint(e.clientX, e.clientY)

      switch(this.drawingMode) {
        case 'pen':
          return this.handleDrawing(e)
        case 'select':
          return this.handleSelectionMoved()
        default:
          break
      }
    }
  },
  /**
   * Handles a selection being deleted. The items that are removed
   * depends on the selection type.
   */
  handleSelectionDeleted() {
    switch (this.selectionType) {
      case 'fill':
        return this.handleFillSelectionDeleted()
      case 'segment':
        return this.handleSegmentSelectionDeleted()
      default:
        break
    }
  },
  /**
   * Handles a selection being moved. The items that are moved
   * depends on the selection type.
   */
  handleSelectionMoved() {
    let delta = this.getDelta(this.mouseCurrentPoint, this.mouseLastPoint)

    switch (this.selectionType) {
      case 'fill':
        return this.handleFillSelectionMoved(delta)
      case 'segment':
        return this.handleSegmentSelectionMoved(delta)
      default:
        break
    }
  },
  /**
   * Handles a fill selection being deleted.
   */
  handleFillSelectionDeleted() {
    paper.project.getSelectedItems().forEach(item => item.remove())
  },
  /**
   * Handles a fill selection being moved.
   */
  handleFillSelectionMoved(delta) {
    paper.project.getSelectedItems().forEach(item => {
      item.position = item.position.add(delta)
    })
  },
  /**
   * Handles a segment selection being deleted.
   */
  handleSegmentSelectionDeleted() {
    paper.project.getSelectedItems().forEach(item => {
      item.segments.forEach(segment => {
        if (segment.selected) {
          segment.remove()
        }
      })
      if (item.segments.length < this.minimumPointsPerPath) {
        item.remove()
      }
    })
  },
  /**
   * Handles a segment selection being moved.
   */
  handleSegmentSelectionMoved(delta) {
    paper.project.getSelectedItems().forEach(item => {
      item.segments.forEach(segment => {
        if (segment.selected) {
          segment.point = segment.point.add(delta)
        }
      })
    })
  },
  /**
   * Handles a drawing event. This triggers continuously while
   * the mouse is pressed.
   */
  handleDrawing(e) {
    let point = this.createPoint(e.clientX, e.clientY)
    let distance = this.getDistance(point, this.path.getNearestPoint(point))
    let distanceToBeginning = this.getDistance(point, this.path.segments[0].point)
    let segmentsLength = this.path.segments.length

    if (distance > this.drawResolution) {
      this.path.add(point)
    } else if (distanceToBeginning < this.drawResolution && segmentsLength > this.minimumPointsPerPath) {
      this.finishDrawing();
    }
  },
  /**
   * Handles a mouseup event. This triggers once per click,
   * when the mouse is released.
   */
  handleMouseUp(e) {
    this.mouseCurrentPoint = this.createPoint(e.clientX, e.clientY)
    this.mouseLastPoint = this.createPoint(e.clientX, e.clientY)
    this.mousePressed = false

    if (this.drawingMode === 'pen') {
      this.finishDrawing();
    }
  },
  /**
   * Pushes a persist event to the server, passing the current
   * drawing encoded as JSON.
   */ 
  handlePersist() {
    this.pushEvent(this.persistEventName, {
      drawing: paper.project.exportJSON()
    });
  },
  /**
   * Finishes the current drawing path and releases the mouse.
   */
  finishDrawing() {
    this.mousePressed = false

    if (this.path.segments.length > this.minimumPointsPerPath) {
      this.path.add(this.path.firstSegment.point)
    } else {
      this.path.remove()
    }
  }
}
export default PaperCanvas