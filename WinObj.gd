class_name WinObj

var origin: Vector2
var size: Vector2
var padding: Vector2

func _init(_origin: Vector2, _size: Vector2, _padding: Vector2 = Vector2.ZERO) -> void:
    self.origin = _origin
    self.size = _size
    self.padding = _padding

func make_rect() -> Rect2:
    return Rect2(self.origin, self.size)

func set_padding(_padd: Vector2) -> void:
    self.padding = _padd

func get_origin_with_padding() -> Vector2:
    return self.origin + self.padding

func get_size_with_padding() -> Vector2:
    return self.size - 2 * self.padding

func get_center() -> Vector2:
    return self.origin + self.size * 0.5

func make_sub_windows(n: int, vsplit: bool, child_padding: Vector2 = Vector2.ZERO, gap: float = 0.0) -> Array[WinObj]:
    var sub_windows: Array[WinObj] = []
    var parent_origin = self.get_origin_with_padding()
    var parent_size = self.get_size_with_padding()
    
    # If vsplit == True => use parent_size.y as L
    if vsplit:
        # cell_size_(x/y) = ( L - (n - 1) * g ) / n
        var cell_size_y = (parent_size.y - (n - 1) * gap) / n
        var cell_size = Vector2(parent_size.x, cell_size_y)
        
        for i in range(0, n):
            var cell_origin = parent_origin + Vector2.DOWN * i * (cell_size_y + gap)
            sub_windows.append(WinObj.new(cell_origin, cell_size, child_padding))
        
        return sub_windows
    else:
        # If vsplit == False => take parent_size.x as L
        var cell_size_x = (parent_size.x - (n - 1) * gap) / n
        var cell_size = Vector2(cell_size_x, parent_size.y)
        for i in range(0, n):
            var cell_origin = parent_origin + Vector2.RIGHT * i * (cell_size_x + gap)
            sub_windows.append(WinObj.new(cell_origin, cell_size, child_padding))
        
        return sub_windows