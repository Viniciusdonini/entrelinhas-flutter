import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/book.dart';

/// An original, decorative cover derived from the book's own title.
class BookCover extends StatelessWidget {
  const BookCover(this.book, {super.key, this.width, this.height});

  final Book book;
  final double? width;
  final double? height;

  Color get _coverColor {
    final titleHash = book.title.runes.fold<int>(
      0,
      (hash, rune) => (hash * 31 + rune) & 0x7fffffff,
    );
    return Color.lerp(
      AppColors.covers[titleHash % AppColors.covers.length],
      AppColors.ink,
      AppColors.coverShade,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final coverColor = _coverColor;
    final decorationColor = AppColors.coverInk.withValues(
      alpha: AppColors.coverDecorationOpacity,
    );

    return Semantics(
      image: true,
      label: book.title,
      excludeSemantics: true,
      child: SizedBox(
        width: width ?? AppSpacing.coverWidth,
        height: height ?? AppSpacing.coverHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xxs),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final coverWidth = constraints.maxWidth;
              final innerWidth = coverWidth * 0.7;
              return ColoredBox(
                color: coverColor,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: coverWidth * 0.07,
                      child: ColoredBox(color: decorationColor),
                    ),
                    Positioned(
                      right: -coverWidth * 0.35,
                      bottom: -coverWidth * 0.3,
                      child: Container(
                        width: coverWidth,
                        height: coverWidth,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: decorationColor,
                            width: AppSpacing.borderWidth,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        coverWidth * 0.18,
                        coverWidth * 0.15,
                        coverWidth * 0.12,
                        coverWidth * 0.15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: coverWidth * 0.16,
                            color: AppColors.coverInk,
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 5,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: innerWidth,
                                  child: Text(
                                    book.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontSize: coverWidth * 0.15,
                                      color: AppColors.coverInk,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: innerWidth * 0.3,
                            child: Divider(
                              color: decorationColor,
                              height: AppSpacing.borderWidth,
                              thickness: AppSpacing.borderWidth,
                            ),
                          ),
                          SizedBox(height: coverWidth * 0.08),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topLeft,
                                child: SizedBox(
                                  width: innerWidth,
                                  child: Text(
                                    book.author,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: coverWidth * 0.09,
                                      color: AppColors.coverInk,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
