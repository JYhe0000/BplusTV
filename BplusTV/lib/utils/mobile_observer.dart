import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver;

void addObserverMobile(WidgetsBindingObserver observer) {
  WidgetsBinding.instance.addObserver(observer);
}

void removeObserverMobile(WidgetsBindingObserver observer) {
  WidgetsBinding.instance.removeObserver(observer);
}
