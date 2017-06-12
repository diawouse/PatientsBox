import { NgModule } from '@angular/core';
import { IonicPageModule } from 'ionic-angular';
// import { Calendar } from './calendar';
import { CalendarPage } from './calendar';

@NgModule({
  declarations: [
    CalendarPage,
  ],
  imports: [
    IonicPageModule.forChild(CalendarPage),
  ],
  exports: [
    CalendarPage
  ]
})
export class CalendarModule {}
