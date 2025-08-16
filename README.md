classDiagram
  class OWNER {
    +Полный доступ
  }
  class ADMIN {
    +Почти полный
    -Нет удаления/transfer
  }
  class USER {
    +Ограниченный
    -ARM/DISARM по флагу
  }
  class GUEST {
    +Только просмотр
  }

  OWNER <|-- ADMIN
  ADMIN <|-- USER
  USER <|-- GUEST
