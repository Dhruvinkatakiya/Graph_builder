import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tree_app/models/tree_node.dart';
import 'package:tree_app/models/graph_layout.dart';
import 'package:tree_app/widgets/animated_node.dart';
import 'package:tree_app/widgets/edge_painter.dart';
import 'package:tree_app/widgets/bottom_bar.dart';

class GraphBuilderPage extends StatefulWidget {
  const GraphBuilderPage({super.key});

  @override
  State<GraphBuilderPage> createState() => _GraphBuilderPageState();
}

class _GraphBuilderPageState extends State<GraphBuilderPage>
    with TickerProviderStateMixin {
  final Map<int, TreeNode> _nodesById = {};
  int _selectedId = 1;
  final Set<int> _appearingIds = {};
  final Set<int> _deletingIds = {};
  late GraphLayout _layout;
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  final double _minScale = 0.1;
  final double _maxScale = 5.0;
  final double _verticalGap = 140;
  final double _nodeRadius = 28;
  final double _minNodeSpacing = 70;
  final EdgeInsets _canvasPadding = const EdgeInsets.symmetric(
    horizontal: 100,
    vertical: 100,
  );

  Widget _buildPopup(BuildContext context, String title, String message) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.white,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.grey.shade800,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          message,
          style: GoogleFonts.inter(
            height: 1.5,
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            "Close",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    final root = TreeNode(id: 1, parentId: null, depth: 0);
    _nodesById[root.id] = root;
    _selectedId = 1;
    _appearing(root.id);
    _layout = GraphLayout.empty();
  }

  // --- Tree Node Logic ---
  void _handleSelect(int id) => setState(() => _selectedId = id);

  void _handleAddChild() {
    final parent = _nodesById[_selectedId];
    if (parent == null) return;
    final nextDepth = parent.depth + 1;
    if (nextDepth >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum depth reached!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final newId = _nodesById.keys.isEmpty
          ? 1
          : (_nodesById.keys.reduce((a, b) => a > b ? a : b) + 1);
      final newNode = TreeNode(
        id: newId,
        parentId: parent.id,
        depth: nextDepth,
      );
      _nodesById[newId] = newNode;
      parent.childrenIds.add(newId);
      _appearing(newId);
      _selectedId = newId;
    });
  }

  void _handleDeleteNode(int nodeId) {
    if (nodeId == 1) return; // Don't delete root
    setState(() {
      final subtree = _collectSubtreeIds(nodeId);
      _deletingIds.addAll(subtree);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        final subtree = _collectSubtreeIds(nodeId);
        for (final id in subtree) {
          final node = _nodesById[id];
          if (node != null && node.parentId != null) {
            _nodesById[node.parentId]?.childrenIds.remove(id);
          }
          _nodesById.remove(id);
        }
        _deletingIds.removeAll(subtree);
        if (_nodesById.isEmpty) {
          final root = TreeNode(id: 1, parentId: null, depth: 0);
          _nodesById[root.id] = root;
          _selectedId = 1;
          _appearing(root.id);
          return;
        }
        if (!_nodesById.containsKey(_selectedId))
          _selectedId = _nodesById.keys.first;
      });
    });
  }

  Set<int> _collectSubtreeIds(int id) {
    final result = <int>{};
    void dfs(int nid) {
      if (result.contains(nid)) return;
      result.add(nid);
      final node = _nodesById[nid];
      if (node == null) return;
      for (final c in node.childrenIds) dfs(c);
    }

    dfs(id);
    return result;
  }

  void _appearing(int id) {
    _appearingIds.add(id);
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) setState(() => _appearingIds.remove(id));
    });
  }

  // --- Zoom Controls ---
  void _resetZoom() => _setZoom(1.0);

  void _zoomIn() => _setZoom(_currentScale * 1.2);

  void _zoomOut() => _setZoom(_currentScale / 1.2);

  void _setZoom(double scale) {
    final newScale = scale.clamp(_minScale, _maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() => _currentScale = newScale);
  }

  // --- Reset Tree ---
  void _handleResetTree() {
    setState(() {
      _nodesById.clear();
      _appearingIds.clear();
      _deletingIds.clear();
      final root = TreeNode(id: 1, parentId: null, depth: 0);
      _nodesById[root.id] = root;
      _selectedId = 1;
      _appearing(root.id);
      _layout = GraphLayout.empty();
    });
    _resetZoom();
  }

  // --- Layout ---
  GraphLayout _computeLayout(Size viewport) {
    if (_nodesById.isEmpty) return GraphLayout.empty();
    final root = _nodesById[1];
    if (root == null) return GraphLayout.empty();
    final positions = <int, Offset>{};

    // --- Compute subtree width recursively ---
    double _subtreeWidth(TreeNode node) {
      if (node.childrenIds.isEmpty) {
        return _minNodeSpacing; // leaf has base width
      }
      double width = 0;
      for (final cid in node.childrenIds) {
        final child = _nodesById[cid]!;
        width += _subtreeWidth(child);
      }
      // Add spacing between siblings
      width += (node.childrenIds.length - 1) * _minNodeSpacing;
      return width;
    }

    void layoutNode(TreeNode node, double centerX, double y) {
      positions[node.id] = Offset(centerX, y);
      if (node.childrenIds.isEmpty) return;

      // Total width of this subtree
      final totalWidth = _subtreeWidth(node);
      double startX = centerX - totalWidth / 2;

      for (final cid in node.childrenIds) {
        final child = _nodesById[cid]!;
        final childWidth = _subtreeWidth(child);

        final childCenter = startX + childWidth / 2;
        layoutNode(child, childCenter, y + _verticalGap);

        startX += childWidth + _minNodeSpacing;
      }
    }

    layoutNode(root, 0, 0);

    double minX = positions.values.map((o) => o.dx).reduce(min);
    double maxX = positions.values.map((o) => o.dx).reduce(max);
    double minY = positions.values.map((o) => o.dy).reduce(min);
    double maxY = positions.values.map((o) => o.dy).reduce(max);

    final treeWidth = maxX - minX;
    final treeHeight = maxY - minY;

    final requiredWidth = max(
      treeWidth + _canvasPadding.horizontal,
      viewport.width,
    );
    final requiredHeight = max(
      treeHeight + _canvasPadding.vertical + _nodeRadius * 2,
      viewport.height,
    );

    final centerOffset = Offset(
      (requiredWidth - treeWidth) / 2 - minX,
      _canvasPadding.top - minY,
    );

    final transformed = {
      for (var e in positions.entries) e.key: e.value + centerOffset,
    };
    return GraphLayout(
      positions: transformed,
      size: Size(requiredWidth, requiredHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        _layout = _computeLayout(
          Size(constraints.maxWidth, constraints.maxHeight),
        );

        return Scaffold(
          appBar: _buildAppBar(size),

          body: _buildBody(),
          bottomNavigationBar: BottomBar(
            onAdd: _handleAddChild,
            onDelete: () => _handleDeleteNode(_selectedId),
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onResetZoom: _resetZoom,
            selectedId: _selectedId,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Size size) {
    return AppBar(
      elevation: 4,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade900, Colors.green.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Text(
            'Graph Builder',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: size.width * 0.05,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: "Reset Zoom",
                onPressed: _resetZoom,
                icon: const Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              IconButton(
                tooltip: "Reset Tree",
                onPressed: _handleResetTree,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == "how") {
                    showDialog(
                      context: context,
                      builder: (ctx) => _buildPopup(
                        ctx,
                        "How Application Works",
                        "• The tree starts with a single root node labeled '1'.\n\n"
                            "• Tap on any node to select it.\n\n"
                            "• Once a node is selected:\n"
                            "   - Tap 'Add Child' to create a new child node.\n"
                            "   - Tap 'Delete' to remove that particular node and all its children.\n\n"
                            "• Use the 'Reset Tree' button to delete the current tree and start a new one.\n\n"
                            "• Use the 'Reset Zoom' button to reset the zoom level.\n\n"
                            "• You can also zoom in and out using two-finger gestures.\n\n"
                            "• This allows you to interactively build and explore a dynamic tree structure.",
                      ),
                    );
                  } else if (value == "tech") {
                    showDialog(
                      context: context,
                      builder: (ctx) => _buildPopup(
                        ctx,
                        "Technical Implementation",
                        "• Data Structure:\n"
                            "  The tree is stored as a map of node IDs → TreeNode objects.\n"
                            "  Each node keeps track of its children IDs.\n\n"
                            "• Node Creation:\n"
                            "  When you add a child, a new TreeNode is created with an incremented ID "
                            "and linked to the selected parent.\n\n"
                            "• Layout Algorithm:\n"
                            "  - Recursive tidy tree algorithm (like Reingold-Tilford).\n"
                            "  - First, compute width of each subtree (_subtreeWidth).\n"
                            "  - Then assign child positions so big subtrees push smaller ones aside.\n"
                            "  - Prevents overlap automatically.\n\n"
                            "• Rendering:\n"
                            "  - CustomPainter (EdgePainter) draws connecting edges.\n"
                            "  - Nodes are widgets; tapping selects them.\n\n"
                            "• Interactions:\n"
                            "  - BottomBar controls Add, Delete, Zoom, Reset Zoom.\n"
                            "  - setState() rebuilds layout whenever tree changes.",
                      ),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: "how",
                    child: Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        Text(
                          "How Application Works",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: "tech",
                    child: Row(
                      children: [
                        Icon(Icons.code, color: Colors.green.shade600),
                        const SizedBox(width: 12),
                        Text(
                          "Technical Details",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Drawer _buildDrawer(BuildContext context) {
  //   return Drawer(
  //     child: ListView(
  //       padding: EdgeInsets.zero,
  //       children: [
  //         DrawerHeader(
  //           decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
  //           child: const Text('Graph Builder', style: TextStyle(color: Colors.white, fontSize: 20)),
  //         ),
  //         ListTile(leading: const Icon(Icons.account_tree), title: const Text('View Graph'), onTap: () => Navigator.pop(context)),
  //         ListTile(leading: const Icon(Icons.add_box), title: const Text('Add Node'), onTap: () => Navigator.pop(context)),
  //         ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () => Navigator.pop(context)),
  //         const Divider(),
  //         ListTile(leading: const Icon(Icons.info), title: const Text('About'), onTap: () => Navigator.pop(context)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBody() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: _minScale,
        maxScale: _maxScale,
        boundaryMargin: const EdgeInsets.all(1000),
        constrained: false,
        child: SizedBox(
          width: _layout.size.width,
          height: _layout.size.height,
          child: Stack(
            children: [
              CustomPaint(
                size: _layout.size,
                painter: EdgePainter(
                  nodes: _nodesById,
                  positions: _layout.positions,
                  deletingIds: _deletingIds,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.35),
                ),
              ),
              ..._nodesById.values
                  .where((node) => _layout.positions.containsKey(node.id))
                  .map((node) {
                    final pos = _layout.positions[node.id]!;
                    return AnimatedPositioned(
                      key: ValueKey('pos-${node.id}'),
                      duration: const Duration(milliseconds: 320),
                      left: pos.dx - _nodeRadius,
                      top: pos.dy - _nodeRadius,
                      child: AnimatedNode(
                        id: node.id,
                        label: node.id.toString(),
                        radius: _nodeRadius,
                        selected: node.id == _selectedId,
                        isAppearing: _appearingIds.contains(node.id),
                        isDeleting: _deletingIds.contains(node.id),
                        onTap: () => _handleSelect(node.id),
                        onDelete: () => _handleDeleteNode(node.id),
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
