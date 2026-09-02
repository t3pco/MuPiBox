import { Component, AfterViewInit } from '@angular/core'
import { ModalController, IonContent, IonGrid, IonRow, IonCol, IonButton, IonInput } from '@ionic/angular/standalone'
import Keyboard from 'simple-keyboard'

@Component({
  selector: 'app-sleeptimer',
  templateUrl: './sleeptimer.component.html',
  styleUrls: ['./sleeptimer.component.scss'],
  standalone: true,
  imports: [IonContent, IonGrid, IonRow, IonCol, IonButton, IonInput],
})
export class SleepTimerComponent implements AfterViewInit {
  keyboard: any
  selectedInputElem: any
  minutes = '60'

  constructor(private modalCtrl: ModalController) {}

  ngAfterViewInit() {
    this.keyboard = new Keyboard({
      onChange: (input: string) => {
        this.minutes = input
        if (this.selectedInputElem) {
          try {
            this.selectedInputElem.value = input
          } catch (e) {}
        }
      },
      onKeyPress: (button: string) => {
        if (button === '{bksp}') {
          this.minutes = this.minutes.slice(0, -1)
          this.keyboard.setInput(this.minutes)
        }
        if (button === '{enter}') {
          this.closeStart()
        }
      },
      layout: {
        default: ['1 2 3', '4 5 6', '7 8 9', '{bksp} 0 {enter}'],
      },
      display: {
        '{bksp}': '⌫',
        '{enter}': 'OK',
      },
      theme: 'hg-theme-default hg-theme-ios',
    })

    this.keyboard.setInput(this.minutes)
    this.selectedInputElem = document.querySelector('#sleeptimer-input') || null
  }

  focusChanged(event: any) {
    this.selectedInputElem = event.target
    this.keyboard.setOptions({ inputName: event.target.name })
  }

  inputChanged(event: any) {
    const v = event.target.value || ''
    this.keyboard.setInput(String(v))
  }

  closeCancel() {
    this.modalCtrl.dismiss(null)
  }

  closeStart() {
    const raw = String(this.minutes || '').replace(/[^0-9]/g, '')
    const mins = parseInt(raw || '0', 10)
    if (!isNaN(mins) && mins > 0) {
      this.modalCtrl.dismiss({ minutes: mins })
    }
  }
}
