library responsive_grid;

import 'package:flutter/widgets.dart';

//
// scaling
//

double _scalingMargin = 5;
double _refWidth = 375;

double? _scalingFactor;
double? _width;

void initScaling(BuildContext context) {
  var mq = MediaQuery.of(context);
  _width = mq.size.width < mq.size.height ? mq.size.width : mq.size.height;
  _scalingFactor = _width! / _refWidth;

  print("width => $_width");
}

double scale(double dimension) {
  if (_width == null) {
    throw Exception("You must call init() before any use of scale()");
  }
  //
  return dimension * _scalingFactor!;
}

//
// responsive grid layout
//

enum _GridTier { xs, sm, md, lg, xl }

_GridTier _currentSize(BuildContext context) {
  MediaQueryData mediaQueryData = MediaQuery.of(context);
  double width = mediaQueryData.size.width;

//  print(
//      "INFO orientation: ${mediaQueryData.orientation} , width: ${mediaQueryData.size.width}, height: ${mediaQueryData.size.height}");

  if (width < 576) {
    return _GridTier.xs;
  } else if (width < 768) {
    return _GridTier.sm;
  } else if (width < 992) {
    return _GridTier.md;
  } else if (width < 1200) {
    return _GridTier.lg;
  } else {
    // width >= 1200
    return _GridTier.xl;
  }
}

class ResponsiveGridRow extends StatelessWidget {
  final List<ResponsiveGridCol> children;
  final CrossAxisAlignment crossAxisAlignment;
  final int rowSegments;

  ResponsiveGridRow(
      {required this.children,
      this.crossAxisAlignment = CrossAxisAlignment.start,
      this.rowSegments = 12});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    int accumulatedWidth = 0;
    var cols = <Widget>[];

    children.forEach((col) {
      var colWidth = col.currentConfig(context) ?? 1;
      //
      if (accumulatedWidth + colWidth > rowSegments) {
        if (accumulatedWidth < rowSegments) {
          cols.add(Spacer(
            flex: rowSegments - accumulatedWidth,
          ));
        }
        rows.add(Row(
          children: cols,
        ));
        // clear
        cols = <Widget>[];
        accumulatedWidth = 0;
      }
      //
      cols.add(col);
      accumulatedWidth += colWidth;
    });

    if (accumulatedWidth >= 0) {
      if (accumulatedWidth < rowSegments) {
        cols.add(Spacer(
          flex: rowSegments - accumulatedWidth,
        ));
      }
      rows.add(Row(
        crossAxisAlignment: this.crossAxisAlignment,
        children: cols,
      ));
    }

    return Column(
      children: rows,
    );
  }
}

class ResponsiveGridCol extends StatelessWidget {
  final _config = <int?>[]..length = 5;
  final Widget child;

  ResponsiveGridCol({
    int xs = 12,
    int? sm,
    int? md,
    int? lg,
    int? xl,
    required this.child,
  }) {
    _config[_GridTier.xs.index] = xs;
    _config[_GridTier.sm.index] = sm ?? _config[_GridTier.xs.index];
    _config[_GridTier.md.index] = md ?? _config[_GridTier.sm.index];
    _config[_GridTier.lg.index] = lg ?? _config[_GridTier.md.index];
    _config[_GridTier.xl.index] = xl ?? _config[_GridTier.lg.index];
  }

  int? currentConfig(BuildContext context) {
    return _config[_currentSize(context).index];
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: currentConfig(context) ?? 1,
      child: child,
    );
  }
}

//
// responsive grid list
//

class ResponsiveGridList extends StatelessWidget {
  final double desiredItemWidth, minSpacing;
  final List<Widget> children;
  final bool squareCells, scroll;
  final MainAxisAlignment rowMainAxisAlignment;
  final bool shrinkWrap;


  ResponsiveGridList({
    required this.desiredItemWidth,
    this.minSpacing = 1,
    this.squareCells = false,
    this.scroll = true,
    required this.children,
    this.rowMainAxisAlignment = MainAxisAlignment.start,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (children.length == 0) return Container();

        double width = constraints.maxWidth;

        double N = (width - minSpacing) / (desiredItemWidth + minSpacing);

        int n;
        double spacing, itemWidth;

        if (N % 1 == 0) {
          n = N.floor();
          spacing = minSpacing;
          itemWidth = desiredItemWidth;
        } else {
          n = N.floor();

          double dw =
              width - (n * (desiredItemWidth + minSpacing) + minSpacing);

          itemWidth = desiredItemWidth +
              (dw / n) * (desiredItemWidth / (desiredItemWidth + minSpacing));

          spacing = (width - itemWidth * n) / (n + 1);
        }

        if (scroll) {
          return ListView.builder(
              shrinkWrap: shrinkWrap,
              itemCount: (children.length / n).ceil() * 2 - 1,
              itemBuilder: (context, index) {
                //if (index * n >= children.length) return null;
                //separator
                if (index % 2 == 1) {
                  return SizedBox(
                    height: minSpacing,
                  );
                }
                //item
                final rowChildren = <Widget>[];
                index = index ~/ 2;
                for (int i = index * n; i < (index + 1) * n; i++) {
                  if (i >= children.length) break;
                  rowChildren.add(children[i]);
                }
                return _ResponsiveGridListItem(
                  mainAxisAlignment: this.rowMainAxisAlignment,
                  itemWidth: itemWidth,
                  spacing: spacing,
                  squareCells: squareCells,
                  children: rowChildren,
                );
              });
        } else {
          final rows = <Widget>[];
          rows.add(SizedBox(
            height: minSpacing,
          ));
          //
          for (int j = 0; j < (children.length / n).ceil(); j++) {
            final rowChildren = <Widget>[];
            //
            for (int i = j * n; i < (j + 1) * n; i++) {
              if (i >= children.length) break;
              rowChildren.add(children[i]);
            }
            //
            rows.add(_ResponsiveGridListItem(
              mainAxisAlignment: this.rowMainAxisAlignment,
              itemWidth: itemWidth,
              spacing: spacing,
              squareCells: squareCells,
              children: rowChildren,
            ));

            rows.add(SizedBox(
              height: minSpacing,
            ));
          }

          return Column(
            children: rows,
          );
        }
      },
    );
  }
}

class _ResponsiveGridListItem extends StatelessWidget {
  final double spacing, itemWidth;
  final List<Widget> children;
  final bool squareCells;
  final MainAxisAlignment mainAxisAlignment;

  _ResponsiveGridListItem({
    required this.itemWidth,
    required this.spacing,
    required this.squareCells,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: this.mainAxisAlignment,
      children: _buildChildren(),
    );
  }

  List<Widget> _buildChildren() {
    final list = <Widget>[];

    list.add(SizedBox(
      width: spacing,
    ));

    children.forEach((child) {
      list.add(SizedBox(
        width: itemWidth,
        height: squareCells ? itemWidth : null,
        child: child,
      ));
      list.add(SizedBox(
        width: spacing,
      ));
    });

    return list;
  }
}
