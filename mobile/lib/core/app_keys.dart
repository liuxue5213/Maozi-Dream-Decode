import 'package:flutter/material.dart';

/// 全局根导航 Key，供 Dio 拦截器等非 UI 层做页面跳转
final rootNavigatorKey = GlobalKey<NavigatorState>();
