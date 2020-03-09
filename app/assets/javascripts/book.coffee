# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


//= require underscore
//= require canvas-toBlob
//= require file_saver.min
//= require dat.gui.min
//= require paper-core
//= require clipper
//= require paper2
//= require ruler

###############################  
###############################  
###############################  
###############################  
###############################  

class window.PaperJSApp
  ###
  Constructor
  ----
  Runs when a new instance of ColoringBook is invoked. If the global dat.gui 
  instance is found in the global scope, it will add button triggers to the 
  dat.gui controller. Lastly, it invokes the setup routine.
  ###
  
  constructor: (ops)->
    this.name = ops.name or "paperjs app"
    @setup(ops)
    console.log "✓ Paperjs Functionality"
    
  
  ###
  setup
  ----
  Configures the supplied canvasDOM element to fill the height and width of 
  its parent. It then installs the paper library in its scope. 
  ###
  
  setup: (ops)->
    canvas = ops.canvas[0]
    parent = $(ops.canvas[0]).parent()
   
    $(canvas)
      .attr('width', parent.width())
      .attr('height', parent.height())
    window.paper = new paper.PaperScope
    loadCustomLibraries()
    paper.setup canvas
    paper.view.zoom = 1
    $(canvas)
      .attr('width', parent.width())
      .attr('height', parent.height())
    if gui
      gui.add(paper.view, "zoom").min(0.1).max(10).step(0.1)
      
    
  ###
  save_svg
  ---
  Captures the current zoom level, changes to zoom level 1, produces an svg
  string of the scene graph, emits a file save actions, then restores the canvas
  to its original zoom level. 
  ###
  save_svg: ()->
    prev = paper.view.zoom;
    console.log("Exporting file as SVG");
    paper.view.zoom = 1;
    paper.view.update();
    exp = paper.project.exportSVG
      asString: true,
      precision: 5
    saveAs(new Blob([exp], {type:"application/svg+xml"}), @name + ".svg")
    paper.view.zoom = prev
    
  ###
  clear
  ----
  Removes all content from the canvas
  ###
  clear: ->
    paper.project.clear()
  ###
  ungroup
  ---
  A helper function for dissolving hierarchical structure of SVG.
  ###
  ungroup: (g)->
    _.each g.children, (child)->
      paper.project.activeLayer.appendTop(child)
  # Defined in inheritance
  toolEvents: ()-> return
  
  
  
###############################  
###############################  
###############################  
###############################  
###############################  
###############################  
###############################  
  
  
  
class window.ColoringBook extends PaperJSApp
  # Coloring page files are located in public > coloring_pages
  @DEFAULT_COLORING_PAGE: "/coloring_pages/mandala.svg"
  @DEFAULT_TOOL: "rainbowBucket"
  constructor: (ops)->
    super ops # Adds core functionality from PaperJSApp
    console.log "✓ ColoringBook Functionality"
    if gui
      gui.add this, "name"
      gui.add this, "clear"
      gui.add this, "load_page"
      gui.add this, "save_svg"
    @load_page()
    
  load_page: ()->
    @addColoringPage
      url: ColoringBook.DEFAULT_COLORING_PAGE
      position: paper.view.center
  
  ###
  addColoringPage
  --
  Places SVG in center of canvas. 
  ops = 
    url: url of the SVG asset (string, required)
    position: where to place paths (paper.Point, default: paper.view.center)
  ###
  addColoringPage: (ops)->
    scope = this
    console.log "\t> Coloring Page Loading:", ops.url

    # POSITION HANDLING
    if not ops.position
      ops.position = paper.view.center
    ops.position = ops.position.clone()

    paper.project.importSVG ops.url, 
      expandShapes: false
      insert: true
      onError: (item)->
        alertify.error "Could not load", ops.url
      onLoad: (item) ->  
        item.position = ops.position
        item.fitBounds(paper.view.bounds.expand(-100))
        # alertify.success "Loaded", ops.url
        scope.createTools()
  
  updateToolController: ()->
    scope = this
    this.activeTool = "" 
    this.toolController = gui.add(this, "activeTool", _.pluck paper.tools, "name").listen()
    this.toolController.onChange (v)->
      console.log "FINISH"
      tool_matches = _.filter paper.tools, (t)-> t.name == v
      if tool_matches.length > 0
        paper.tool = tool_matches[0]
      else
        console.log "\t No tool found"
      console.log "\t✓ ", paper.tool.name,"Tool Enabled"
      this.activeTool = v

  createTools: ()->
    scope = this
    hitOptions =   
      stroke: false
      fill: true
      tolerance: 1
      minDistance: 10
    
    cp = new ColorPalette()
    ###
    Turns everything red.
    ####
    window.redBucket = new paper.Tool
      name: "redBucket"
      onMouseDown: (event)->
        scope = this
        hitResults = paper.project.hitTestAll event.point, hitOptions
        _.each hitResults, (h)->
          # Don't color black lines
          if h.item.fillColor.brightness == 0
            return
          h.item.set
            fillColor: "red"
            dirty: true
              
    ###
    Turns everything into a rainbow fill.
    ####
    window.rainbowBucket = new paper.Tool
      name: "rainbowBucket"
      onMouseDrag: (event)->
        scope = this
        hitResults = paper.project.hitTestAll event.point, hitOptions
        _.each hitResults, (h)->
          # Don't color black lines
          if h.item.fillColor.brightness == 0
            return
          if h.item.ui
            return
          h.item.set
            dirty: true
            fillColor: 
              gradient:
                stops: ['yellow', 'red', 'blue']
              origin: h.item.bounds.topLeft,
              destination: h.item.bounds.bottomRight
              
    ###
    MODULE III
    ###
    
    window.historyTracker = new paper.Tool
      name: "paintBucket"
      onMouseDown: (event)->
        scope = this
        
        palette = paper.project.getItem
          name: "palette"
          
        if palette and palette.lastColor
          hitResults = paper.project.hitTestAll event.point, hitOptions
          _.each hitResults, (h)->
            # Don't color black lines
            if h.item.fillColor.brightness == 0
              return
            if h.item.ui
              return
            h.item.set
              fillColor: palette.lastColor
              dirty: true
      
    window.historyTracker = new paper.Tool
      name: "historyTracker"
      onMouseDown: (event)->
        scope = this
        alertify.error "TODO!"
      
    window.Kaleidoscope = new paper.Tool
      name: "1 - Fun Coloring"
      onMouseDown: (event)->
        scope = this
        palette = paper.project.getItem
          name: "palette"
      
        # GET THE ITEM PATH CLICKED
        hitResults = paper.project.hitTestAll event.point, hitOptions
        
        # FOR EACH ITEM PATH CLICKED
        _.each hitResults, (el)->
          clickedPath = el.item
          # Don't color black lines
          if el.item.fillColor.brightness == 0
            return
            
          clickedPath.fillColor = palette.lastColor
          
          # GET CENTER OF THE ITEM PATH
          clickedPath_center = clickedPath.position
          
          # GET POINTS OF ITEM PATH THAT IS 90, 180, -90 DEGREE AWAY FROM ITEM
          points = k_paths(clickedPath_center,4)
          
          # GET PATH THAT CONTAINS THE POINTS
          allPaths = paper.project.getItems({class: "Path"})
          paths = []
          _.each points, (p) ->
            path = _.filter allPaths, (path)-> return(path.contains(p))
            Array::push.apply paths, path
          
          # COMPARE AREA AND PERIMETER OF THOSE PATHS WITH ORIGINAL
          
          
          # IF HAVING SIMILAR AREA AND PARAMETER, COLOR THOSE PATHS OF POINTS
          
          _.each paths, (el)->
            el.fillColor = palette.lastColor
            el.set
              dirty: true
          
          # CHANGE COLOR EVERY TIME DONE CLICKING
          palette.lastColor = paper.Color.random() #Not working
          # or when changing colot on the color palla
          

      k_paths = (p,n) ->
        degree = 360/n
        points = (1 for [0..n-1]) 
        center = paper.view.center
        i = 0

        _.each points, (el)->
          point = new paper.Point(p.rotate(i*degree,center))
          points.push point
          i += 1
        
        beg = n/2
        end = n-1
        res = points[4..8]
        return res
        
    window.autocomplete = new paper.Tool
      name: "2 - Autocomplete"  
      onMouseDown: (event)->
        scope = this
        # palette = paper.project.getItem
        #   name: "palette"
          
        # if palette and palette.lastColor
        #   hitResults = paper.project.hitTestAll event.point, hitOptions
        #   _.each hitResults, (h)->
        #     # Don't color black lines
        #     if h.item.fillColor.brightness == 0
        #       return
        #     if h.item.ui
        #       return
        #     h.item.set
        #       fillColor: palette.lastColor
       
            # SELECT ALL PATH 
            # allPaths = paper.project.getItems({class: "Path"})
            
            # FILTER PATHS OF THE PAINT
            
            
            # COLOR SELECTED PATHS
            # _.each selectedPaths, (p)->
            #   p.fillColor = paper.Color(palette.lastColor,0.2)
          
            
         
          # h.item.selected = true;
          
        
        allPaths = paper.project.getItems({class: "Path"})
        compoundPaths = paper.project.getItems({class: "CompoundPath"})
        colorCompoundPaths = []
        _.each compoundPaths, (path)->
          if path.fillColor.brightness == 0
            path.fillColor = "black"
          else
            if !path.dirty
              path.fillColor = paper.Color.random()
              path.set
                dirty: true
        palette = paper.project.getItem
          name: "palette"
        ui = palette.getItems
          ignoreSelection: "true"
        
        colorSpots = _.filter allPaths, (path)-> return(path not in ui)

        _.each colorSpots, (colorSpot)->
          if !colorSpot.dirty
            colorSpot.fillColor = paper.Color.random()
            colorSpot.set
              dirty: true
    ###
    swatches = palette.getItems
      name: "swatch"
    
    _.each swatches, (s)->
      s.set
        onMouseDown: (e)->
          palette.lastColor = this.fillColor
          
    ###             

    # MUST BE THE LAST LINES IN CREATE_TOOLS          
    scope.updateToolController()
    
    # DEFAULT TOOL
    this.activeTool = ColoringBook.DEFAULT_TOOL
    tool_matches = _.filter paper.tools, (t)-> t.name == scope.activeTool
    if tool_matches.length > 0
      paper.tool = tool_matches[0]
      
### ACCESS PALETTE THROUGH THE SCENE GRAPH
.LASTCOLOR -> LAST COLOR GET CLICKED ON
###
class window.ColorPalette 
  constructor: ()->
    console.log "Making color palette"
    this.make_ui()
    this.bindInteraction()
  make_ui: ()->
    
    # DEFINE A COLOR RANGE
    num_of_swatches = 8
    c = new paper.Color("red")
    hues = _.range(0, 360, 360/num_of_swatches)
    
    # CREATE A CONTAINER
    g = new paper.Group
      name: "palette"
      colorable: false
    
    # GENERATE A CIRCLE FOR EACH HUE, PLACE IN GROUP
    _.each hues, (h, i)->
      color = c.clone()
      color.hue = h
      color.saturation = 0.8
      
      stroke_color = color.clone()
      stroke_color.brightness = stroke_color.brightness - 0.3
      swatch = new paper.Path.Circle
        name: "swatch"
        ignoreSelection: "true"
        parent: g
        radius: 20
        fillColor: color
        position: paper.view.center.clone().add(new paper.Point(43 * i, 0))
        strokeColor: stroke_color
        strokeWidth: 4
        strokeScaling: true
        ui: true
        
    # ADD BACKGROUND TO GROUP
    bg = new paper.Path.Rectangle
      ignoreSelection: "true"
      parent: g
      rectangle: g.bounds.expand(15)
      fillColor: new paper.Color(0.9)
      radius: 10
      shadowBlur: 5
      shadowOffset: new paper.Point(1, 1)
      shadowColor: new paper.Color(0, 0, 0, 0.5)
      ui: true
      
    bg.sendToBack()
    
    # POSITION PALETTE GROUP IN UI
    g.set
      position: paper.view.bounds.bottomCenter.add(new paper.Point(0, -1 * g.bounds.height - 20))
    g.scale(2)
    
  bindInteraction: ()->
    palette = paper.project.getItem
      name: "palette"
    
    palette.lastColor = null
      
    # FOR EACH SWATCH, IF IT IS CLICKED, THEN UPDATE THE STATE OF THE PALETTE SCENE OBJECT  
    swatches = palette.getItems
      name: "swatch"
    
    _.each swatches, (s)->
      s.set
        onMouseDown: (e)->
          palette.lastColor = this.fillColor
          
          