# flutter_monitoring_health

Um plugin Flutter para monitorar a saúde do dispositivo e realizar testes de velocidade de internet.

## Recursos

- Obter modelo do celular
- Obter versão do sistema operacional
- Obter total de memória do dispositivo
- Obter total de memória em uso
- Obter total de memória em uso pelo aplicativo
- Obter total de espaço em disco
- Obter total de espaço em disco utilizado
- Obter total de espaço em disco disponível
- Realizar teste de velocidade de internet (download e upload)

## Começando

Para usar este plugin, adicione `flutter_monitoring_health` como uma [dependência no seu arquivo pubspec.yaml](https://flutter.dev/platform-plugins/).

### Exemplo

```dart
import 'package:flutter/material.dart';
import 'package:flutter_monitoring_health/monitoring_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MonitoringPage(),
    );
  }
}
```

## Uso

O plugin fornece uma página pronta para uso que exibe todas as informações coletadas. Para usá-la, basta importar `MonitoringPage` e adicioná-la à sua árvore de widgets.

Se você preferir acessar as informações individualmente, você pode usar os métodos estáticos da classe `FlutterMonitoringHealth`:

```dart
import 'package:flutter_monitoring_health/flutter_monitoring_health.dart';

// Obter modelo do celular
String deviceModel = await FlutterMonitoringHealth.getDeviceModel();

// Obter versão do sistema operacional
String osVersion = await FlutterMonitoringHealth.getOSVersion();


## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.
