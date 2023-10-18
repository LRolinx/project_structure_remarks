import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '项目结构说明生成工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,

      ),
      home: const MyHomePage(title: '项目结构说明生成工具'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Future<List<MyTreeNode>> dirList() async {
    String path = Directory.current.path;
    List<String> rootsp = path.toString().split('\\');

    final List<MyTreeNode> dictRoots = [
      MyTreeNode(
          title: '${rootsp[rootsp.length - 1]}',
          parentpath: rootsp[0],
          path: path,
          remarks: '',
          isfolder: true,
          children: []),
    ];

    Stream<FileSystemEntity> fileList = Directory(path).list(recursive: true);
    await for (FileSystemEntity fileSystemEntity in fileList) {
      List<String> sp = fileSystemEntity.path.toString().split('\\');
      var data = MyTreeNode(
          title: sp[sp.length - 1],
          parentpath: fileSystemEntity.parent.path,
          path: fileSystemEntity.path,
          isfolder: FileSystemEntity.isDirectorySync(fileSystemEntity.path),
          children: []);

      // 写入字典列表
      dictRoots
          .firstWhereOrNull((element) => element.path == data.parentpath)
          ?.children
          .add(data);
      dictRoots.add(data);

      // print('$fileSystemEntity');
    }

    // 排序
    dictRoots.forEach((element) {
      element.children.sort((a, b) {
        int ab = a.isfolder == true ? 1 : 0;
        int ba = b.isfolder == true ? 1 : 0;
        return a.title.compareTo(b.title) & ba.compareTo(ab);
      });
    });

    // 筛出根目录 并返回
    List<MyTreeNode> roots = [
      dictRoots.firstWhereOrNull((element) => element.path == path)
          as MyTreeNode
    ];

    return roots;
  }

  @override
  Widget build(BuildContext context) {

    late List<MyTreeNode> roots = [];

    final treeController = TreeController<MyTreeNode>(
      roots: roots,
      childrenProvider: (MyTreeNode node) => node.children,
    ).obs;

    dirList().then((value) {
      roots = value;
      treeController.value = TreeController<MyTreeNode>(
        roots: roots,
        childrenProvider: (MyTreeNode node) => node.children,
      );
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Obx(
        () => AnimatedTreeView(
          treeController: treeController.value,
          nodeBuilder: (BuildContext context, TreeEntry<MyTreeNode> entry) {
            return InkWell(
                onTap: () => treeController.value.toggleExpansion(entry.node),
                child: Container(
                  padding: EdgeInsets.only(top: 4, bottom: 4),
                  child: TreeIndentation(
                      // guide: IndentGuide.connectingLines(),
                      entry: entry,
                      child: Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(left: 4, right: 4),
                            child: Text(entry.node.isfolder ? ' 📂 ' : ' 📄 '),
                          ),
                          Text(entry.node.title),

                          Container(
                            margin: EdgeInsets.only(left: 4),
                            child: TextButton(
                                onPressed: () {},
                                child: Text(entry.node.remarks.isEmpty  ? '请编辑':'')),
                          )
                        ],
                      )),
                ));
          },
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MyTreeNode {
  const MyTreeNode({
    required this.title,
    this.remarks = '',
    this.parentpath = '',
    this.path = '',
    this.isfolder = false,
    this.children = const <MyTreeNode>[],
  });

  // 标题
  final String title;

  // 父路径
  final String parentpath;

  // 路径
  final String path;

  // 说明
  final String remarks;

  // 是否文件夹
  final bool isfolder;

  // 子级
  final List<MyTreeNode> children;
}
