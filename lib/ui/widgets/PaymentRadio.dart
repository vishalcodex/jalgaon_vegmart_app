
import 'package:flutter/material.dart';

import '../styles/Color.dart';
import 'package:flutter_svg/flutter_svg.dart';
class RadioItem extends StatelessWidget {
    final RadioModel _item;

    const RadioItem(this._item, {Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
                children: <Widget>[
                    Container(
                        height: 20.0,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _item.isSelected! ? colors.primary : Theme.of(context).colorScheme.white,
                            border: Border.all(color: colors.primary)),
                        child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: _item.isSelected!
                                ? Icon(
                                Icons.check,
                                size: 15.0,
                                color: Theme.of(context).colorScheme.white,
                            )
                                : Icon(
                                Icons.circle,
                                size: 15.0,
                                color: Theme.of(context).colorScheme.white,
                            ),
                        ),
                    ),
                    Padding(
                        padding: const EdgeInsetsDirectional.only(start:15.0),
                        child: Text(_item.name!,style: TextStyle(color:Theme.of(context).colorScheme.fontColor),),
                    ),
                    const Spacer(),
                    _item.img != "" ? SvgPicture.asset(_item.img!) : Container()
                ],
            ),
        );
    }
}

class RadioModel {
    bool? isSelected;
    final String? img;
    final String? name;

    RadioModel({this.isSelected, this.name, this.img});
}
