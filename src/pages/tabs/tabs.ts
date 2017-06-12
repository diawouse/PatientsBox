import { Component } from '@angular/core';
import { IonicPage, NavController, NavParams } from 'ionic-angular';
import { HomePage } from '../home/home';
import { PatientsPage } from '../patients/patients';
import { CalendarPage } from '../calendar/calendar';


@IonicPage()
@Component({
  selector: 'page-tabs',
  templateUrl: 'tabs.html',
})

  export class TabsPage {
    tab1Root: any = HomePage;
    tab2Root: any = CalendarPage;
    tab3Root: any = PatientsPage;
    mySelectedIndex: number;

	constructor(public navCtrl: NavController, public navParams: NavParams) {
   this.mySelectedIndex = navParams.data.tabIndex || 0;
  	}

  	ionViewDidLoad() {
    console.log('ionViewDidLoad TabsPage');
  	}

}
