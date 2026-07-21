import { Component } from '@angular/core';
import { addIcons } from 'ionicons';
import {
  storefrontOutline,
  receiptOutline,
  leafOutline,
  personOutline,
  personCircleOutline,
  logInOutline,
} from 'ionicons/icons';

@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
  standalone: false,
})
export class AppComponent {
  constructor() {
    addIcons({
      storefrontOutline,
      receiptOutline,
      leafOutline,
      personOutline,
      personCircleOutline,
      logInOutline,
    });
  }
}
