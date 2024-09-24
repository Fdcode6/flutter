import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '俄罗斯方块',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TetrisGame(),
    );
  }
}

class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});

  @override
  _TetrisGameState createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  static const int rowCount = 20;
  static const int columnCount = 10;
  static const int squareSize = 20;

  List<List<Color>> grid = List.generate(
    rowCount,
    (i) => List.generate(columnCount, (j) => Colors.black),
  );

  List<List<List<int>>> shapes = [
    [
      [1, 1, 1, 1]
    ],
    [
      [1, 1],
      [1, 1]
    ],
    [
      [1, 1, 0],
      [0, 1, 1]
    ],
    [
      [0, 1, 1],
      [1, 1, 0]
    ],
    [
      [1, 1, 1],
      [0, 1, 0]
    ],
    [
      [1, 1, 1],
      [1, 0, 0]
    ],
    [
      [1, 1, 1],
      [0, 0, 1]
    ],
  ];

  List<List<int>> currentShape = [];
  int currentRow = 0;
  int currentColumn = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    setState(() {
      grid = List.generate(
        rowCount,
        (i) => List.generate(columnCount, (j) => Colors.black),
      );
      spawnShape();
      timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        moveDown();
      });
    });
  }

  void spawnShape() {
    final random = Random();
    currentShape = shapes[random.nextInt(shapes.length)];
    currentRow = 0;
    currentColumn = columnCount ~/ 2 - currentShape[0].length ~/ 2;
  }

  void moveDown() {
    setState(() {
      if (!checkCollision(currentRow + 1, currentColumn)) {
        currentRow++;
      } else {
        placeShape();
        clearLines();
        spawnShape();
        if (checkCollision(currentRow, currentColumn)) {
          timer?.cancel();
          showGameOverDialog();
        }
      }
    });
  }

  void moveLeft() {
    setState(() {
      if (!checkCollision(currentRow, currentColumn - 1)) {
        currentColumn--;
      }
    });
  }

  void moveRight() {
    setState(() {
      if (!checkCollision(currentRow, currentColumn + 1)) {
        currentColumn++;
      }
    });
  }

  void rotateShape() {
    setState(() {
      final newShape = List.generate(
        currentShape[0].length,
        (i) => List.generate(currentShape.length,
            (j) => currentShape[currentShape.length - j - 1][i]),
      );
      if (!checkCollision(currentRow, currentColumn, newShape)) {
        currentShape = newShape;
      }
    });
  }

  bool checkCollision(int row, int column, [List<List<int>>? shape]) {
    shape ??= currentShape;
    for (int i = 0; i < shape.length; i++) {
      for (int j = 0; j < shape[i].length; j++) {
        if (shape[i][j] == 1) {
          final newRow = row + i;
          final newColumn = column + j;
          if (newRow >= rowCount ||
              newColumn < 0 ||
              newColumn >= columnCount ||
              grid[newRow][newColumn] != Colors.black) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void placeShape() {
    for (int i = 0; i < currentShape.length; i++) {
      for (int j = 0; j < currentShape[i].length; j++) {
        if (currentShape[i][j] == 1) {
          grid[currentRow + i][currentColumn + j] = Colors.blue;
        }
      }
    }
  }

  void clearLines() {
    setState(() {
      grid.removeWhere((row) => row.every((color) => color != Colors.black));
      while (grid.length < rowCount) {
        grid.insert(0, List.generate(columnCount, (j) => Colors.black));
      }
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('游戏结束'),
          content: const Text('你输了！'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
              child: const Text('重新开始'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('俄罗斯方块'),
      ),
      body: Center(
        child: GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 0) {
              moveRight();
            } else if (details.delta.dx < 0) {
              moveLeft();
            }
          },
          onTap: rotateShape,
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) {
              moveDown();
            }
          },
          child: CustomPaint(
            size: Size(columnCount * squareSize.toDouble(),
                rowCount * squareSize.toDouble()),
            painter: TetrisPainter(
                grid, currentShape, currentRow, currentColumn, squareSize),
          ),
        ),
      ),
    );
  }
}

class TetrisPainter extends CustomPainter {
  final List<List<Color>> grid;
  final List<List<int>> currentShape;
  final int currentRow;
  final int currentColumn;
  final int squareSize;

  TetrisPainter(this.grid, this.currentShape, this.currentRow,
      this.currentColumn, this.squareSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[i].length; j++) {
        paint.color = grid[i][j];
        canvas.drawRect(
          Rect.fromLTWH(j * squareSize.toDouble(), i * squareSize.toDouble(),
              squareSize.toDouble(), squareSize.toDouble()),
          paint,
        );
      }
    }

    for (int i = 0; i < currentShape.length; i++) {
      for (int j = 0; j < currentShape[i].length; j++) {
        if (currentShape[i][j] == 1) {
          paint.color = Colors.blue;
          canvas.drawRect(
            Rect.fromLTWH(
                (currentColumn + j) * squareSize.toDouble(),
                (currentRow + i) * squareSize.toDouble(),
                squareSize.toDouble(),
                squareSize.toDouble()),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
