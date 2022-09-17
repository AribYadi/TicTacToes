package;

import haxe.display.Display.Package;

enum Player {
  None;
  One;
  Two;
}

class Tile {
  public final row: Int;
  public final col: Int;
  public var player: Player;

  public var rowsClose = 0;
  public var colsClose = 0;
  public var diagsClose = 0;
  public var oppDiagsClose = 0;

  public function new(row, col, player) {
    this.row = row;
    this.col = col;
    this.player = player;
  }

  public function update(row, col, player) {
    if (player == this.player) {
      if (row == this.row) ++rowsClose;
      if (col == this.col) ++colsClose;
      if (row != this.row && col != this.col) {
        if (row == col) ++diagsClose;
        if (row + col + 1 == Board.SIZE) ++oppDiagsClose;
      }
    }
  }
}

class Board {
  public static final SIZE = 3;

  var board = [for (i in 0...Board.SIZE * Board.SIZE) new Tile(i % Board.SIZE, Std.int(i / Board.SIZE), Player.None)];
  var currPlayer = Player.One;

  var quit = false;
  var selectedRow = 0;
  var selectedCol = 0;

  public function new() {}

  public function run() {
    Sys.print('\x1B[?25l');
    while (!this.quit) this.tick();
    Sys.print('\x1B[?25h');
  }

  function printTable() {
    for (tile in this.board) {
      final tileCh = switch tile.player {
        case Player.None: '.';
        case Player.One: 'X';
        case Player.Two: 'O';
      };
      Sys.print(
        if (selectedRow == tile.row && selectedCol == tile.col) '[$tileCh]'
        else ' $tileCh '
      );
      if (tile.row + 1 == Board.SIZE) Sys.println('');
    }
  }

  function handleInput() {
    final inp = Sys.getChar(false);

    switch inp {
      case 'w'.code: --this.selectedCol;
      case 'a'.code: --this.selectedRow;
      case 's'.code: ++this.selectedCol;
      case 'd'.code: ++this.selectedRow;
      case '\n'.code | '\r'.code:
        if (this.board[this.selectedCol * Board.SIZE + this.selectedRow].player == Player.None) {
          this.board[this.selectedCol * Board.SIZE + this.selectedRow].player = this.currPlayer;
          for (tile in this.board) if (tile.player != Player.None) tile.update(this.selectedRow, this.selectedCol, this.currPlayer);
          this.currPlayer = switch this.currPlayer {
            case Player.None: Player.None;
            case Player.One: Player.Two;
            case Player.Two: Player.One;
          };
        }
      case 'q'.code | 3: this.quit = true;
    }
    if (this.selectedRow < 0) selectedRow = 0;
    if (this.selectedRow > Board.SIZE - 1) selectedRow = Board.SIZE - 1;
    if (this.selectedCol < 0) selectedCol = 0;
    if (this.selectedCol > Board.SIZE - 1) selectedCol = Board.SIZE - 1;
  }

  function checkWin() {
    var winner = Player.None;
    var full = true;

    var player1Diag = 0;
    var player1OppDiag = 0;

    var player2Diag = 0;
    var player2OppDiag = 0;

    for (tile in this.board) {
      if (full && tile.player == Player.None) full = false;
      switch tile.player {
        case Player.None: {};
        case Player.One:
          player1Diag += tile.diagsClose;
          player1OppDiag += tile.oppDiagsClose;
        case Player.Two:
          player2Diag += tile.diagsClose;
          player2OppDiag += tile.oppDiagsClose;
      }
      if (
        tile.rowsClose == Board.SIZE ||
        tile.colsClose == Board.SIZE ||
        tile.diagsClose == Board.SIZE ||
        tile.oppDiagsClose == Board.SIZE ||
        player1Diag == Board.SIZE ||
        player1OppDiag == Board.SIZE
      ) {
        winner = tile.player;
        break;
      }
    }

    final msg = switch winner {
      case Player.None:
        if (full) 'a tie';
        else return;
      case Player.One: 'player one\'s victory';
      case Player.Two: 'player two\'s victory';
    };
    this.printTable();
    Sys.println('The result was: $msg!\n');
    this.quit = true;
  }

  function goTop() {
    Sys.print('\x1B[3A');
  }

  function tick() {
    this.printTable();
    this.handleInput();
    this.checkWin();
    if (!this.quit) this.goTop();
  }
}
