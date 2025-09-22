enum DeviceKind {
  lightDimmable, // диммер/лампа c brightness
  lightOnOff, // простая лампа
  relay, // розетка/реле (power monitoring)
  curtain, // карниз / шторы
  sensorContact, // дверь/окно
  sensorMotion, // движение
  sensorPresence, // присутствие (mmWave)
  sensorEnv, // температура/влажность/освещенность
  sensorLeak, // протечка
  sensorVibration, // вибрация
  generic, // fallback
}
