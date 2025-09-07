class TreeNode {
  final int id;
  final List<int> childrenIds;
  final int? parentId;
  final int depth;

  TreeNode({
    required this.id, 
    required this.parentId, 
    required this.depth
  }) : childrenIds = [];
}
