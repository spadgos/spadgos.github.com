Introduction to TypeScript

Let's not spend too much time here. I'm going to assume that you already have a basic grasp of TypeScript. If not that, an understanding of FlowJS or even just type systems in general is enough.

Very important thing to remember is that it is a structural typing system, not a nominal typing system. This is not unique (Go uses this), but might be surprising if you're used to Java.

    interface Track {
      id: number;
      title: string;
    }
    interface Playlist {
      id: number;
      title: string;
      tracks: Array<Track>;
    }

    function getTitleFromTrack(track: Track) {
      return track.title;
    }

    const playlist: Playlist = { id: 123, title: 'Cool songs', tracks: [] };
    getTitleFromTrack(playlist); // ok

The other thing to go over just to make sure we're all on the same page is Generics.

    // Built-in at a low level in TS
    const arrOfStrings: Array<string> = [];
    // equivalent to
    const arrOfStrings: string[] = [];

    arrOfStrings.push(3); // error


    // using generics in a function signature
    function identity<T>(x: T): T {
      return x;
    }

    // using generics in an interface
    interface Resource<T> {
      id: T
    }

    interface User extends Resource<number> {}

    interface Track extends Resource<string> {}

    const user: User = { id: 123 };
    const track: Track = { id: 'a32f-b91f-ae00-e011' };

    // same applies for types, can use multiple types
    type NTuple2<A, B> = [A, B]
    type NTuple3<A, B, C> = [A, B, C]

    type Thunk<T> = T | () => T;

    function extract<T>(val: Thunk<T>): T {
        if (typeof val === 'function') {
            return val();
        }
        return val;
    }

## Using Types in a front end app

If you do some research online about TS, you'll probably find some tutorials telling you how great it is because it stops this from happening:

    const thing = 'abc';
    const thingSquared = thing * thing; // err, can't multiply strings

This is obviously a good thing for your tools to prevent, but in real applications, this is not really a very common class of error that crops up.

Where types really help are checking that the inputs and outputs of functions are the correct shape, and this is something which isn't necessarily too difficult to get right. Let's take a look at an example:

    interface Person {
      firstName: string;
      lastName: string;
    }

    function getFullName(person: Person): string {
      return person.firstName + ' ' + person.lastName;
    }

    const person: Person = { firstName: 'Grace', lastName: 'Hopper' };
    const name = getFullName(user);

This is great. It works. It protects you against passing in the wrong data, but when I see examples like this, there's one line which stands out to me.

    const person: Person = { firstName: 'Grace', lastName: 'Hopper' };

Almost certainly, this is not how you get data into your application. It would make type-checking a lot easier, but I really hope no one is writing their database as source code. Hopefully, the way that data makes it into your front end looks a bit more like this:

DATABASE
   |
   v
BACK END
   |
   v
FRONT END

Let's zoom in on the important part here:

1. Back end has a domain model
2. Serialization into transport format (probably JSON.stringify)
3. Deserialization to consumable form (probably JSON.parse)
4. Hydration into domain model (`new User(data)`, etc)

Let's look closer at step 4. What I've seen in the wild is something like this:

    makeRequest(`users/${id}`).then(parseUserResponse);

    function parseUserResponse(data: any): User {
      return data;
    }

    // or
    function parseUserResponse(data: any): User {
      return {
        id: data.id,
        firstName: data.firstName,
        // etc
      };
    }

The obvious problem here is that if the API changes the data it is sending, there's no checks on it at all. Of course, this is a problem with any integration between systems, and there are ways to enforce contracts, but even with contract testing, you'd need to write interfaces and keep them in sync with the server's contract. As a developer working on the front end, you still have to trust the data coming in, and as a back end developer, you don't know if the changes you're making are going to break the front end.

Let's take a closer look at a different part of this code:

    makeRequest(`users/${id}`).then(parseUserResponse);

This `makeRequest` function is presumably a wrapper around some HTTP transport (eg: `fetch` or an `XMLHttpRequest`), but what is its signature? It looks like it takes a string, and returns a promise of _something_. Looking even closer though, the string passed into it is the actual function call here. You could image 'getUsers' is the function which takes a parameter `id`. If we start thinking about the API as if it were a local library of functions which took parameters and returned values, how would it be different?

## Endpoints

This is a technique we started doing a few years ago at SoundCloud. Rather than let any part of the app call the API, building URLs all over the place, we made a central list of named endpoints. Each endpoint defined the url template it maps to, and can list the query parameters it accepts, including default values. For example:

    const endpoints = {
      user: {
        url: '/users/:id'
      },
      userTracks: {
        url: '/users/:id/tracks',
        query: {
          limit: 10
        }
      },
      trackStats: {
        url: '/tracks/:id/stats/:category' // eg: 'plays', 'likes', 'reposts'
      }
    }

And then when you want to use one of these, you could call it by name:

    const data = Endpoints.callEndpoint('userTracks', { id: 123 }, { limit: 5 });

There's a lot of benefits here.
  - The most obvious part is that it's a lot cleaner to work with, since you're not building urls and having to worry about escaping.
  - Testing becomes easier, since you've abstracted the api access away and can more-easily stub its calls.
  - It makes it a lot easier to find the places in your application which are accessing certain endpoints
  - If you ever need to change your api structure, there's a single file which needs to be updated.

However here, we're still in Javascript land. There's no validation of the inputs, and no promise on the return types. When you want to add typescript into the mix here, you can probably start to see where the benefits come in.

Let's take a look at how you might add types to this function.

    const Endpoints = {
      callEndpoint(endpointName, pathParams, queryParams) {
        // do some magic to construct the url from the configuration
        return fetch(url);
      }
    }

Let's make an type for Endpoints

    const Endpoints: EndpointsInstance = {
      // as above
    }

    type EndpointsInstance = {
      callEndpoint: (name: string, pathParams: object, queryParams: object) => Promise<object>;
    }

Basic start, but not much to build on from here. We don't want to take _any_ string, and we don't want to take _any_ url params. Thankfully, TypeScript has literal data types that we can use. To keep it simple, let's add types just for the `userTracks` example from before. We also need to define what the response looks like.

    type EndpointsInstance = {
      callEndpoint: (name: 'userTracks', pathParams: { id: number }, queryParams: { limit?: number }) => Promise<UserTracksResponse>;
    }

    type UserTracksResponse = Array<Track>;
    type Track = { id: number; title: string };

Ok, it's looking good now!

    Endpoints.callEndpoint('userTracks', { id: 123 }, { limit : 5 }).then((response) => {
      // response is of type Array<Track>
    });

**live coding here to show the type hinting? Gif?**

Right now though, there's nothing else that TypeScript will let us call with this endpoint. It only accepts 'userTracks' as its first parameter. Let's add the types for another endpoint. To do this we'll need to use intersections types to say that `callEndpoint` is a function that could take different forms. The literal types will be enough to tell the type checker what the outputs will be.

    type EndpointsInstance = {
      callEndpoint: ((name: 'userTracks', pathParams: { id: number }, queryParams: { limit?: number }) => Promise<UserTracksResponse>)
                  & ((name: 'user', pathParams: { id: number }, queryParams: {}) => Promise<User>);
    }

    Endpoints.callEndpoint('userTracks', { id: 123 }, { limit : 5 }).then((response) => {
      // response is of type Array<Track>
    });

    Endpoints.callEndpoint('user', { id: 123 }, {}).then((response) => {
      // response is of type User
    });

This is ok, but has some problems:

1. It isn't very friendly to developers. Though we look at it and see the name of the endpoint as an invariant, the type checker can't make that inference. It means the intellisense is actually quite broken, and the error messages you get if something is wrong don't help. If any of the parameters don't match one of the call signatures, the type checker can't tell which one is actually invalid.
2. It's getting pretty ugly and repetitive. There's a lot of duplicated information in each definition, like there's always a fixed number of arguments, and you always get Promise as the response.

Addressing point one is achievable with a little trick. If you change the signature of the method so that it's a curried function, you can basically 'lock in' the endpoint that you want to call, and the type checker can provide a lot more help.

    // from this
    (name: string, pathParams: object, queryParams: object) => Promise<object);

    // to this
    (name: string) => (pathParams: object, queryParams: object) => Promise<object);

    Endpoints.callEndpoint('user')({ id: 123 }, {}).then((user) => ...);

It's not the best, since up until now we haven't had to make any changes to the runtime. Remember that after compiling to Javascript, all the type information is removed, so we leave no trace in the runtime of this extra machinery. It's a trade-off I had to make here, but I don't think it's too bad. This is how the type signatures look now:

    type EndpointsInstance = {
      callEndpoint: ((name: 'userTracks') => (pathParams: { id: number }, queryParams: { limit?: number }) => Promise<UserTracksResponse>)
                  & ((name: 'user') => (pathParams: { id: number }, queryParams: {}) => Promise<User>);
    }

We've added in the extra higher-order function into the signature, which of course makes the other problem we had even worse. But, we have a nice solution for this too by using generics.

    type Endpoint<N, P, Q, R> = (name: N) => (pathParams: P, queryParams: Q) => Promise<R>

Here, we've created a type alias for each call signature of `callEndpoints` which eliminates the boilerplate. Applying this to the example we have makes it read a lot nicer

    type EndpointsInstance = {
      callEndpoint: Endpoint<'userTracks', { id: number }, { limit?: number }, UserTracksResponse>
                  & Endpoint<'user', { id: number }, {}, User>;
    }

We can also organise our code into modules which export a series of endpoints and join them all together in one place

    // search-endpoints.ts
    export Users = Endpoint<'searchUsers', null, { query: string }, Array<User>>
    export Tracks = Endpoint<'searchTracks', null, { query: string }, Array<Track>>

    // user-endpoints.ts
    export User = Endpoint<'user', { id: number }, {}, User>

    // main.ts
    import * as Search from './search-endpoints';
    import * as User from './user-endpoints';

    type EndpointsInstance = {
      callEndpoint: Search.Users
                  & Search.Tracks
                  & User.User;
    }

**Not sure if it's imporant, but...**

One nice thing about this is that actual implementation of callEndpoint can be very relaxed, and just use the `any` type. The compiler will trust the type we assign to it in this case.

    const Endpoints: EndpointsInstance = {
      callEndpoint(name: any) {
        return (pathParams: any, queryParams: any) => {
          return fetch(/* the constructed url */);
        };
      }
    };

So now, we have some types for the endpoints we're calling, and we can be sure we're passing the correct parameters to them, but how do we know that we got it right? I had to write an interface for the shape of the response, but nothing is verifying that it's actually correct here. This is where I realised that we actually have all the necessary pieces to write contract tests here. Let's look at what data we have and what we'd need to know whether our definitions were correct.

If we called the endpoint to get a user object, how could we tell if the response is the shape we expect? One way would be to look at the actual response from the API and check that each key matches the interface we wrote in our code. This means we need to call the API, and then we need to check each field. Taking another look at what we're writing here, all the pieces are here.

    callEndpoint('user')({ id: 123 }, {});

This is literally the way that we call the API to get a response, and because everything in this code is written out as literals, it's possible to statically analyse this code and execute the call, using the library itself. This means we can get the fixture from the API, but then how do we check that it's the type we expect? What if there was a method which took all the same parameters as `callEndpoint` but instead of returning a promise of the return type, it returned a function which took the response as an argument? Here I'll call it verify.

    verify('user')({ id: 123 }, {}); // returns a function which expects a User to be passed in

To do the actual verification of the data returned by the API, we could write that data into the script itself and run it through TypeScript.

    verify('user')({ id: 123 }, {})({
      id: 123,
      firstName: 'Jimmy',
      lastName: 'Page'
    });

If the data returned by the API doesn't match the type definition we wrote, we'd get an error message here.

So this means that for our tests, we'd need to define two function signatures, one for `verify` and one for `callEndpoint`. Seems repetitive? Nope!

    type Endpoint<N, P, Q, R> = {
      callEndpoint: (name: N) => (pathParams: P, queryParams: Q) => Promise<R>;
      verify: (name: N) => (pathParams: P, queryParams: Q) => (expectedResult: R) => void;
    }

This changes the definition of the EndpointsInstance just a slight bit:

    type EndpointsInstance = {
      callEndpoint: Search.Users['callEndpoint']
                  & Search.Tracks['callEndpoint']
                  & User.User['callEndpoint']
    }

And for our tests, we can define a function called `verify` like so

    const VerifyFn = Search.Users['verify']
                   & Search.Tracks['verify']
                   & User.User['verify']
    const verify: VerifyFn = (name: any) => (pathParams: any, queryParams: any) => (expectedResult: any) => {};
