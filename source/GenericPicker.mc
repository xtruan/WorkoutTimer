using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Calendar;

enum
{
    GENERIC_PICKER_Number,
    GENERIC_PICKER_Time,
    GENERIC_PICKER_Bool
}
    
class NumberFactory extends Ui.PickerFactory
{
    hidden var _maxSize;
    function initialize(maxSize)
    {
        PickerFactory.initialize();
        _maxSize = maxSize;
    }
    function getDrawable(item, isSelected)
    {
        return new Ui.Text({:text=>item.toString(),
                            //:color=>Gfx.COLOR_WHITE,
                            :font=>Gfx.FONT_NUMBER_MEDIUM,
                            //:justification=>Gfx.TEXT_JUSTIFY_LEFT,
                            :locX =>Ui.LAYOUT_HALIGN_CENTER,
                            :locY=>Ui.LAYOUT_VALIGN_CENTER});
    }
    function getSize()
    {
        return _maxSize;
    }
    function getValue(item)
    {
        return item;
    }
}

class MyConfirmationDelegate extends Ui.ConfirmationDelegate
{
    hidden var _object;
    hidden var _symbol;
    function initialize(object, symbol)
    {
        ConfirmationDelegate.initialize();
        _object = object;
        _symbol = symbol;
    }
        
    function onResponse(value)
    {                
        _object[_symbol] = value == 1;
        _object[:PickerUpdated] = true;
    }    
}

class MyPickerDelegate extends Ui.PickerDelegate
{
    hidden var _mode;
    hidden var _object;
    hidden var _symbol;    
    
    function initialize(mode, object, symbol)
    {
        PickerDelegate.initialize();
        _mode = mode;
        _object = object;
        _symbol = symbol;
    }
    
    function onAccept( values )
    {   
        // Single Value 
        if(values.size() == 1)
        {                   
            _object[_symbol] = values[0]; 
        }
        else if(_mode == GENERIC_PICKER_Time && values.size() == 2)
        {                   
           _object[_symbol] = Calendar.duration( {:hours=>0, :minutes=>values[0], :seconds=>values[1]} ).value();       
        }
        _object[:PickerUpdated] = true;
        Ui.popView(Ui.SLIDE_DOWN);
        return true;
    }
    function onCancel( )
    {
        Ui.popView(Ui.SLIDE_DOWN);
        return true;
    }
}

class GenericPickerDialog
{    
    function initialize(mode, title, object, symbol)
    {                
        var value = object[symbol];
        if(mode == GENERIC_PICKER_Number && value instanceof Toybox.Lang.Number)
        {            
            Ui.pushView(new Ui.Picker({
                                :title=>new Ui.Text({
                                    :text=>title,
                                    :font=>Gfx.FONT_SMALL,
                                    :locX=>Ui.LAYOUT_HALIGN_CENTER,
            				        :locY=>Ui.LAYOUT_VALIGN_CENTER}),
                                :pattern=>[new NumberFactory(100)],
                                :defaults=>[value]}),
                new MyPickerDelegate(mode, object, symbol),
                Ui.SLIDE_UP );
        }
            
        if(mode == GENERIC_PICKER_Bool && value instanceof Toybox.Lang.Boolean)
        {            
            var cd = new Ui.Confirmation( title );        
            Ui.pushView( cd, new MyConfirmationDelegate(object, symbol), Ui.SLIDE_IMMEDIATE ); 
        }
        
        if(mode == GENERIC_PICKER_Time)
        {            
            // Duration Object
            if(!(value instanceof Toybox.Lang.Number))
            {                
                value = value.value();
            }            
            var value1 = 0;
            var value2 = 0;
            if(value >= 60)
            {
                value1 = value / 60;
            }
            value2 = value % 60;            
            Ui.pushView(new Ui.Picker({
                                :title=>new Ui.Text({
                                    :text=>title,
                                    :font=>Gfx.FONT_SMALL,
                                    :locX=>Ui.LAYOUT_HALIGN_CENTER,
            				        :locY=>Ui.LAYOUT_VALIGN_CENTER}),
                                :pattern=>[new NumberFactory(60), new NumberFactory(60)],
                                :defaults=>[value1, value2]}),
                new MyPickerDelegate(mode, object, symbol),
                Ui.SLIDE_UP );
        }        
    }
}