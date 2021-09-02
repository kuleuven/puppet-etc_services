type Etc_services::ServiceName = Pattern[/^(?=.{1,15}$)(?=[A-Za-z0-9])(?=[A-Za-z0-9-]*[A-Za-z0-9]$)(?!.*([-])\1)[A-Za-z0-9-]+$/]
