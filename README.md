# Cod-Notification-Manager
Notification Manager for advanced notifications in Windows 10/11

## Dependencies (provided)
- Cod.ArrayHelpers
- Cod.Registry

## Planned features
- Recieve notification closed message
- Recieve button clicks/input
- Recieve notification failed
- Scheduled notifications

## Examples
### Create notification manager
```
  Manager := TNotificationManager.Create;

  Manager.ApplicationIdentifier := 'App.Test';
  Manager.ShowInSettings := false;

  Manager.ApplicationName := 'Not so Cool test';
```

### Creating a notification
```
  Notif := Manager.CreateNewNotification;
```

### Pushing notification
```
  Notif.Title := 'This is the title';
  Notif.Text := 'This is the text';

  Notif.Image.Source := 'C:\Windows\System32\@facial-recognition-windows-hello.gif';
  Notif.Image.Placement := TImagePlacement.Hero;
  Notif.Image.HintCrop := TImageCrop.Circle;

  Notif.UpdateToastInterface;
  Manager.ShowNotification(Notif);
```

## Important notes
- Do not free the `TNotificationManager` until the app will no longer send notification.
- Do not free the notification until It is no longer needed, because you will no longer be able to hide It. The notification can be reset
