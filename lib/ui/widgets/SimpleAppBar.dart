import 'package:eshop/ui/styles/Color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

getSimpleAppBar(
    String title,
    BuildContext context,
    ) {
  return AppBar(
    elevation: 0,
    titleSpacing: 0,
    backgroundColor: Theme.of(context).colorScheme.white,
    leading: Builder(builder: (BuildContext context) {
      return Container(
        margin: const EdgeInsets.all(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => Navigator.of(context).pop(),
          child: const Center(
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: colors.primary,
            ),
          ),
        ),
      );
    }),
    title: Text(
      title,
      style:
      const TextStyle(color: colors.primary, fontWeight: FontWeight.normal),
    ),
  );
}