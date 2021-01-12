import 'dart:async' show Completer;
//import 'dart:typed_data';
import 'dart:ui' show Image;

import 'package:flutter/material.dart' show runApp, Canvas, Offset, Paint, Rect;
//import 'package:flame/flame.dart';
import 'package:flame/game.dart' show Game, GameWidget;

import './globals.dart';

void main() {
  runApp(GameWidget(game: Console()));
}

const double tileLength = 8;

const Map<int, Rect> tileMapRects = <int, Rect>{
  0: Rect.fromLTWH(0 * tileLength, 0, tileLength, tileLength),
  1: Rect.fromLTWH(1 * tileLength, 0, tileLength, tileLength),
  2: Rect.fromLTWH(2 * tileLength, 0, tileLength, tileLength),
};

class Sprite {
  /// Top, y position.
  int byte0 = 0x0;

  /// Tile index number.
  int byte1 = 0x0;

  /// Attributes.
  ///
  /// bit 7: Flip sprite vertically
  /// bit 6: Flip sprite horizontally
  /// bit 5: Priority (0 in front of background, 1 behind background)
  /// bit 4: unimplemented
  /// bit 3: unimplemented
  /// bit 2: unimplemented
  /// bits 1-0: Palette of sprite
  int byte2 = 0x1 << 5; // set to hidden

  /// Left, x position.
  int byte3 = 0x0;

  //Offset get offset => Offset(byte3.toDouble(), byte0.toDouble());

  /// 0x0 means shown, 0x1 means hidden.
  int get priority => (byte2 & (0x1 << 5)) >> 5;
  set priority(int b) {
    assert(b == 0x1 || b == 0x0);
    if (b == 0x1) {
      byte2 |= (0x1 << 5);
    } else if (b == 0x0) {
      byte2 &= ~(0x1 << 5);
    } else {
      throw RetroVMException('Yikes!');
    }
  }
}

class PictureProcessingUnit {
  final List<Sprite> sprites = List<Sprite>.generate(
    64,
    (int _index) => Sprite(),
    growable: false,
  );
  Image tileMap;

  void render(Canvas c) {
    // TODO: actually sprites appearing first in memory render on top
    // https://wiki.nesdev.com/w/index.php?title=PPU_OAM&redirect=no#Sprite_overlapping
    sprites.forEach((Sprite sprite) {
      assert(sprite != null);
      // TODO draw the priority == true sprites before background
      if (sprite.priority == 0x1) {
        return;
      }
      c.drawImageRect(
        tileMap,
        tileMapRects[sprite.byte1],
        Rect.fromLTWH(
          sprite.byte3.toDouble(),
          sprite.byte0.toDouble(),
          tileLength,
          tileLength,
        ),
        paint,
      );
    });
  }

  static Paint paint = Paint();
}

class Console extends Game {
  final PictureProcessingUnit ppu = PictureProcessingUnit();

  // registers
  int xRegister = 0x0;
  int yRegister = 0x0;

  Future<void> onLoad() {
    final Completer<void> completer = Completer<void>();

    images.loadAll(<String>[
      'tilemap.png',
    ]).then((List<Image> images) {
      ppu.tileMap = images[0];
      completer.complete();
    });
    return completer.future;
  }

  void render(Canvas c) {
    c.scale(scaleFactor);
    ppu.render(c);
  }

  void update(double t) {
    xRegister += 1;
    if (xRegister == 4) {
      yRegister += 1;
      if (yRegister == 2) {
        ppu.sprites[0].byte1 = 0x1;
        yRegister = 0;
      } else {
        ppu.sprites[0].byte1 = 0x2;
      }
      ppu.sprites[0].byte3 += 1;
      if (ppu.sprites[0].byte3 > 100) {
        ppu.sprites[0].byte3 = 0;
        ppu.sprites[0].byte0 += 1;
        if (ppu.sprites[0].byte0 > 100) {
          ppu.sprites[0].byte0 = 0;
        }
      }
      xRegister = 0;
    }
    ppu.sprites[0].priority = 0x0; // show
  }

  double get scaleFactor => 2;
}
